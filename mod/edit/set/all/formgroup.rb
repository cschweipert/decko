format :html do
  # a formgroup has a label, an input and help text
  def formgroup title, opts={}, &block
    input = opts[:input]
    wrap_with :div, formgroup_div_args(opts[:class]) do
      [formgroup_label(input, title, opts[:help]),
       editor_wrap(input, &block)]
    end
  end

  def formgroup_label input, title, help
    parts = [formgroup_title(title), formgroup_help(help)].compact
    return unless parts.present?

    form.label (input || :content), raw(parts.join("\n"))
  end

  def formgroup_title title
    title if voo&.show?(:title) && title.present?
  end

  def formgroup_div_args html_class
    div_args = { class: ["form-group", html_class].compact.join(" ") }
    div_args[:card_id] = card.id if card.real?
    div_args[:card_name] = h card.name if card.name.present?
    div_args
  end

  def formgroup_help text=nil
    return unless voo&.show?(:help) && text.present?

    class_up "help-text", "help-block"
    voo.help = text if voo && text.to_s != "true"
    _render_help
  end
end
