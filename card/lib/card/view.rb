require_dependency "card/view/visibility"
require_dependency "card/view/cache"

class Card
  class View
    include Visibility
    extend Cache

    @@option_keys = ::Set.new [
      :nest_name,   # name as used in nest
      :nest_syntax, # full nest syntax
      :items,      # handles pipe-based recursion

      # _conventional options_
      :view, :type, :title, :params, :variant,
      :size,        # images only
      :hide, :show, # affects optional rendering
      :structure    # override raw_content
    ]

    cattr_reader :option_keys
    attr_reader :format

    def initialize format, view, args={}
      @format = format
      @original = view
      @original_options = args
    end

    def prepare
      return if hide?
      #fetch do
        yield self, approved, options
        #end
    end

    def fetch &block
      case (level = cache_level)
      when :off  then yield
      when :full then cache_fetch(&block)
      when :stub then stub_nest
      else raise "Invalid cache level #{level}"
      end
    end

    def cache_fetch
      self.class.actively do
        cached_view = fetch cache_key, &block
        cache_strategy == :client ? cached_view : complete_render(cached_view)
      end
    end

    def cache_strategy
      Card.config.view_cache
    end

    def requested
      @requested ||= View.canonicalize @original
    end

    def approved
      @approved ||= format.ok_view requested, pre_options
    end

    # default_X_args not yet run
    def pre_options
      @pre_options ||= case (a = @original_options.clone)
                       when nil   then {}
                       when Hash  then a.clone
                       when Array then a[0].merge a[1]
                       else raise Card::Error, "bad view args: #{a}"
                       end
    end

    def options
      @options ||= format.view_options_with_defaults approved, pre_options.clone
    end

    def style
      options[:style]
    end

    @@option_keys.each do |option_key|
      define_method option_key do
        options[option_key]
      end

      define_method "#{option_key}=" do |value|
        options[option_key] = value
      end
    end

  end
end
