include_set Abstract::FilterFormgroups
include_set Abstract::Utility


def filter_class
  Card::FilterQuery
end

def filter_wql
  return {} if filter_hash.empty?
  filter_class.new(filter_keys_with_values, blocked_id_wql).to_wql
end

def blocked_id_wql
  not_ids = filter_param :not_ids
  not_ids.present? ? { id: ["not in", not_ids] } : {}
end

def advanced_filter_keys
  []
end

# def search_wql type_id, opts, params_keys, return_param=nil, &block
#   wql = { type_id: type_id }
#   wql[:return] = return_param if return_param
#   Filter.new(filter_keys_with_values, Env.params[:sort], wql, &wql).to_wql
# end

# all filter keys in the order they were selected
def all_filter_keys
  @all_filter_keys ||= filter_keys_from_params | filter_keys | advanced_filter_keys
end

def filter_keys
  [:name]
end

def filter_keys_from_params
  filter_hash.keys.map(&:to_sym) - [:not_ids]
end

def filter_hash
  @filter_hash ||= begin
    filter = Env.params[:filter]
    filter = filter.to_unsafe_h if filter&.respond_to?(:to_unsafe_h)
    filter.is_a?(Hash) ? filter : {}
  end
end

format :html do
  delegate :filter_hash, to: :card

  def filter_fields slot_selector: nil, sort_field: nil
    form_args = { action: filter_action_path, class: "slotter" }
    form_args["data-slot-selector"] = slot_selector if slot_selector
    filter_form filter_form_data, sort_field, form_args
  end

  def filter_form_data
    all_filter_keys.each_with_object({}) do |cat, h|
      h[cat] = { label: filter_label(cat),
                 input_field: _render("#{cat}_formgroup"),
                 active: show_filter_field?(cat) }
    end
  end

  def show_filter_field? field
    filter_hash[field]
  end

  def filter_label field
    return "Keyword" if field.to_sym == :name
    Card.fetch_name(field) { field.to_s.capitalize }
  end

  def filter_action_path
    path
  end

  view :filter_form, cache: :never do
    filter_fields slot_selector: "._filter-result-slot",
                  sort_field: _render(:sort_formgroup)
  end

  # @param data [Hash] the filter categories. The hash needs for every category
  #   a hash with a label and a input_field entry.
  def filter_form data={}, sort_input_field=nil, form_args={}
    haml :filter_form, categories: data,
         sort_input_field: sort_input_field,
         form_args: form_args
  end

  def sort_options
    { "Alphabetical": :name,
      "Recently Updated": :updated_at
    }
  end

  view :sort_formgroup, cache: :never do
    selected_option = sort_param || card.default_sort_option
    options = options_for_select(sort_options, selected_option)
    select_tag "sort", options, class: "pointer-select _filter-sort",
               "data-minimum-results-for-search" => "Infinity"
  end
end

def default_sort_option
  :name
end
