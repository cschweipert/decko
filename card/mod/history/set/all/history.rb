ACTS_PER_PAGE = Card.config.acts_per_page

def history?
  true
end

# must be called on all actions and before :set_name, :process_subcards and
# :validate_delete_children

def actionable?
  history? || respond_to?(:attachment)
end

event :assign_action, :initialize, when: proc { |c| c.actionable? } do
  @current_act = director.need_act
  @current_action = Card::Action.create(
    card_act_id: @current_act.id,
    action_type: @action,
    draft: (Env.params["draft"] == "true")
  )
  if @supercard && @supercard != self
    @current_action.super_action = @supercard.current_action
  end
end

def finalize_action?
  actionable? && current_action
end

# stores changes in the changes table and assigns them to the current action
# removes the action if there are no changes
event :finalize_action, :finalize,
      when: proc { |c| c.finalize_action? } do
  @changed_fields = Card::Change::TRACKED_FIELDS.select do |f|
    changed_attributes.member? f
  end
  if @changed_fields.present?
    # FIXME: should be one bulk insert
    @changed_fields.each do |f|
      Card::Change.create field: f,
                          value: self[f],
                          card_action_id: @current_action.id
    end
    @current_action.update_attributes! card_id: id
  elsif @current_action.card_changes(true).empty?
    @current_action.delete
    @current_action = nil
  end
end

event :finalize_act,
      after: :finalize_action,
      when: proc { |c|  c.act_card? } do
  # removed subcards can leave behind actions without card id
  if @current_act.actions(true).empty?
    @current_act.delete
    @current_act = nil
  else
    @current_act.update_attributes! card_id: id
  end
end

def act_card?
  self == Card::ActManager.act_card
end

event :rollback_actions, :prepare_to_validate,
      on: :update,
      when: proc { |c| c.rollback_request? } do
  revision = { subcards: {} }
  rollback_actions = Env.params["action_ids"].map do |a_id|
    Action.fetch(a_id) || nil
  end
  rollback_actions.each do |action|
    if action.card_id == id
      revision.merge!(revision(action))
    else
      revision[:subcards][action.card.name] = revision(action)
    end
  end
  Env.params["action_ids"] = nil
  update_attributes! revision
  rollback_actions.each do |action|
    # rollback file and image cards
    action.card.try :rollback_to, action
  end
  clear_drafts
  abort :success
end

def rollback_request?
  history? && Env && Env.params["action_ids"] &&
    Env.params["action_ids"].class == Array
end

# all acts with actions on self and on cards that are descendants of self and
# included in self
def intrusive_family_acts args={}
  @intrusive_family_acts ||= begin
    Act.find_all_with_actions_on((included_descendant_card_ids << id), args)
  end
end

# all acts with actions on self and on cards included in self
def intrusive_acts args={ with_drafts: true }
  @intrusive_acts ||= begin
    Act.find_all_with_actions_on((included_card_ids << id), args)
  end
end

def current_rev_nr
  @current_rev_nr ||= begin
    if intrusive_acts.first.actions.last.draft
      @intrusive_acts.size - 1
    else
      @intrusive_acts.size
    end
  end
end

def included_card_ids
  @included_card_ids ||=
    Card::Reference.select(:referee_id).where(
      ref_type: "I", referer_id: id
    ).pluck("referee_id").compact.uniq
end

def descendant_card_ids parent_ids=[id]
  more_ids = Card.where("left_id IN (?)", parent_ids).pluck("id")
  more_ids += descendant_card_ids more_ids unless more_ids.empty?
  more_ids
end

def included_descendant_card_ids
  included_card_ids & descendant_card_ids
end

format :html do
  view :history do
    voo.show! :toolbar
    @content_body = true
    class_up "card-body",  "history-slot list-group"
    frame do
      "fix tomorrow"
      #[history_legend, _render_act_list]
    end
  end

  view :act_list do |args|
    page = params["page"] || 1
    count = card.intrusive_acts.size + 1 - (page.to_i - 1) * ACTS_PER_PAGE
    card.intrusive_acts.page(page).per(ACTS_PER_PAGE).map do |act|
      count -= 1
      render_act args.merge(act: act, act_seq: count)
    end.join
  end

  def history_legend
    intr = card.intrusive_acts.page(params["page"]).per(ACTS_PER_PAGE)
    render_haml intr: intr do
      <<-HAML.strip_heredoc
        .history-header
          %span.slotter
            = paginate intr, remote: true, theme: 'twitter-bootstrap-3'
          %div.history-legend
            = glyphicon "plus-sign", "added-mark"
            %span
              = Card::Content::Diff.render_added_chunk('Added')
              |
            = glyphicon "minus-sign", "deleted-mark"
            %span
              = Card::Content::Diff.render_deleted_chunk('Removed')
              |
            = glyphicon "trash", "deleted-mark"
            %span
              card deleted
      HAML
    end
  end

  def default_act_args args
    act = (args[:act]  ||= Act.find(params["act_id"]))
    args[:act_seq]     ||= params["act_seq"]
    args[:hide_diff]   ||= hide_diff?
    args[:slot_class]  ||= "revision-#{act.id} history-slot list-group-item"
    args[:action_view] ||= action_view
    args[:actions]     ||= action_list args
  end

  def action_list args
    act = args[:act]
    actions =
      if act_context(args) == :absolute
        act.actions
      else
        act.actions_affecting(card)
      end
    actions.select { |a| a.card && a.card.ok?(:read) }
    # FIXME: should not need to test for presence of card here.
  end

  def act_context args
    args[:act_context] =
      (args[:act_context] || params["act_context"] || :relative).to_sym
  end

  def hide_diff?
    params["hide_diff"].to_s.strip == "true"
  end

  def action_view
    (params["action_view"] || "summary").to_sym
  end

  view :act do |args|
    wrap do
      render_haml args.merge(card: card, args: args) do
        <<-HAML.strip_heredoc
          .act{style: "clear:both;"}
            - show_header = act_context == :absolute ? :show : :hide
            = optional_render :act_header, args, show_header
            .head
              = render :act_metadata, args
            .toggle
              = fold_or_unfold_link args
            .action-container
              - actions.each do |action|
                = render "action_#{args[:action_view]}", args.merge(action: action)
        HAML
      end
    end
  end

  view :act_header do |_args|
    %(<h5 class="act-header">#{link_to_card card}</h5>)
  end

  view :act_metadata, cache: :never do |args|
    render_haml args.merge(card: card, args: args) do
      <<-HAML.strip_heredoc
        - unless act_context == :absolute
          .nr
            = '#' + act_seq.to_s
        .title
          .actor
            = link_to_card act.actor
          .time.timeago
            = time_ago_in_words(act.acted_at)
            ago
            - if act.id == card.last_act.id
              %em.label.label-info Current
            - if action_view == :expanded
              - unless act.id == card.last_act.id
                = rollback_link act.actions_affecting(card)
              = show_or_hide_changes_link args
      HAML
    end
  end

  view :action_summary, cache: :never do |args|
    view_action :summary, args
  end

  view :action_expanded, cache: :never do |args|
    view_action :expanded, args
  end

  def view_action action_view, args
    action = args[:action] || card.last_action
    hide_diff = args[:hide_diff] || hide_diff?
    return trashed_view(action) if action.action_type == :delete
    render_haml action: action,
                action_view: action_view,
                name_diff: name_diff(action, hide_diff),
                type_diff: type_diff(action, hide_diff),
                content_diff: content_diff(action, action_view, hide_diff) do
      <<-HAML.strip_heredoc
        .action
          .summary
            %span.ampel
              = glyphicon 'minus-sign', (action.red? ? 'deleted-mark' : 'diff-invisible')
              = glyphicon 'plus-sign', (action.green? ? 'added-mark' : 'diff-invisible')
            = wrap_diff :name, name_diff
            = wrap_diff :type, type_diff
            -if content_diff && action_view == :summary
              = glyphicon 'arrow-right', 'arrow'
              = wrap_diff :content, content_diff
          -if content_diff and action_view == :expanded
            .expanded
              = wrap_diff :content, content_diff
      HAML
    end
  end

  def trashed_view action
    render_haml action: action do
      <<-HAML.strip_heredoc
        .action
          .summary
            %span.ampel
              = glyphicon 'trash', 'deleted-mark'
            = wrap_diff :name, action.card.name, ('label label-default' if action.card != card)
      HAML
    end
  end

  def name_diff action, hide_diff
    working_name = name_changes action, hide_diff
    if action.card == card
      working_name
    else
      link_to_view(
        :related, working_name,
        path: { related: { view: "history", name: action.card.name } },
        remote: true,
        class: "slotter label label-default",
        "data-slot-selector" => ".card-slot.history-view"
      )
    end
  end

  def type_diff action, hide_diff
    action.new_type? && type_changes(action, hide_diff)
  end

  def content_diff action, action_view, hide_diff
    diff = action.new_content? &&
           action.card.format.render_content_changes(
             action: action, diff_type: action_view, hide_diff: hide_diff
           )
    return "<i>empty</i>" unless diff.present?
    diff
  end

  def wrap_diff field, content, extra_class=nil
    return "" unless content.present?
    %(
       <span class="#{field}-diff #{extra_class}">
       #{content}
       </span>
    )
  end

  def name_changes action, hide_diff=false
    old_name = (name = action.previous_value :name) && showname(name).to_s
    if action.new_name?
      new_name = showname(action.value(:name)).to_s
      if hide_diff
        new_name
      else
        Card::Content::Diff.complete(old_name, new_name)
      end
    else
      old_name
    end
  end

  def type_changes action, hide_diff=false
    change = hide_diff ? action.value(:cardtype) : action.cardtype_diff
    "(#{change})"
  end

  view :content_changes do |args|
    if args[:hide_diff]
      args[:action].raw_view
    else
      args[:action].content_diff(args[:diff_type])
    end
  end

  def fold_or_unfold_link args
    act_id = args[:act].id
    action_view = args[:action_view] == :expanded ? :summary : :expanded
    arrow_dir = args[:action_view] == :expanded ? "arrow-down" : "arrow-right"

    link_to_view :act, "", class: "slotter revision-#{act_id} #{arrow_dir}",
                           path: { act_id:      act_id,
                                   act_seq:     args[:act_seq],
                                   hide_diff:   args[:hide_diff],
                                   act_context: args[:act_context],
                                   action_view: action_view,
                                   look_in_trash: true }
  end

  def rollback_link actions
    # FIXME -- doesn't this need to specify which action it wants?
    prior =  # FIXME - should be a Card::Action method
      actions.select { |action| action.card.last_action_id != action.id }
    return unless card.ok?(:update) && prior.present?
    link = link_to(
      "Save as current", class: "slotter",
                         "data-slot-selector" => ".card-slot.history-view",
                         remote: true, method: :post, rel: "nofollow",
                         path: { action: :update, action_ids: prior,
                                 view: :open, look_in_trash: true }
    )
    %(<div class="act-link">#{link}</div>)
  end

  def show_or_hide_changes_link args
    link = link_to_view(
      :act, "#{args[:hide_diff] ? 'Show' : 'Hide'} changes",
      class: "slotter",
      path: { act_id:      args[:act].id,      act_seq: args[:act_seq],
              hide_diff:  !args[:hide_diff],   action_view: :expanded,
              act_context: args[:act_context], look_in_trash: true }
    )
    %(<div class="act-link">#{link}</div>)
  end
end

def diff_args
  { diff_format: :text }
end

def has_edits?
  Card::Act.where(actor_id: id).where("card_id IS NOT NULL").present?
end
