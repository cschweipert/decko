::Card.error_codes[:conflict] = [:conflict, 409]

def content
  db_content or (new_card? && template.db_content)
end

def content=(value)
  self.db_content = value
end

def raw_content
  structure ? template.db_content : content
end

format do
  def chunk_list #override to customize by set
    :default
  end
end

def label
  name
end

def creator
  Card[ creator_id ]
end

def updater
  Card[ updater_id ]
end

def clean_html?
  true
end

def history?
  false
end

def save_content_draft content
  clear_drafts
end

def clear_drafts
  drafts.created_by(Card::Auth.current_id).each do |draft|
    draft.delete
  end
end

event :save_draft, :before=>:store, :on=>:update, :when=>proc{ |c| Env.params['draft'] == 'true' } do
  save_content_draft content
  abort :success
end


event :set_default_content, :on=>:create, :changed=>:content, :before=>:approve do
  if template and template.db_content.present?
    self.db_content = template.db_content
  end
end

