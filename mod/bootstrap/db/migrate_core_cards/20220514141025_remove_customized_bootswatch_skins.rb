
class RemoveCustomizedBootswatchSkins < Cardio::Migration::Core
  def up
    return unless Card::Codename[:customized_bootswatch_skin]

    clean_up_stylesheet_lists
    convert_bootswatch_skins
    delete_code_card :customized_bootswatch_skin
  end

  def convert_bootswatch_skins
    parent_field_name = Card::Codename.exist?(:parent) ? :parent.cardname : "parent"
    Card.search(type_id: ::Card::CustomizedBootswatchSkinID) do |card|
      update_args = { type_id: Card::BootswatchSkinID, skip: :asset_input_changed }
      parent = find_parent(card.name)
      if parent && parent.id != card.id
        update_args[:subcards] = { "+#{parent_field_name}" => { content: parent.name } }
      end
      fix_stylesheets_field card
      card.field(:variables)&.update content: ""
      card.update! update_args
    end
    Card::Cache.reset_all
  end

  def fix_stylesheets_field skin
    fld = skin.field :stylesheets
    return unless fld.real? && fld.try(:item_names).present?
    fld.content = fld.item_names.select do |i|
      fld.try(:ok_item_types)&.include? i.card&.type_code
    end
    fld.save!
  end

  def find_parent card_name
    potential_parent_name = card_name.downcase.sub("customized", "").gsub(/\d/, "").strip
    Card[potential_parent_name]
  end
end
