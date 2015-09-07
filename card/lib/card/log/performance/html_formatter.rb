class HtmlFormatter

  def initialize performance_logger
    @log = performance_logger.log
    @category_log = performance_logger.category_log
  end

  def output
    @output ||= "#{details}\n#{category_summary}\n"
  end

  def details
    @details ||= begin
          list = @log.inject([]) do |tree, entry|
            if entry.parent
              #entry.parent.children << entry
            else
              tree << entry
            end
            tree
          end

          list_to_accordion list
        end
  end

  def category_summary
    def category_summary
      @category_summary ||=
        begin
          total = 0
          output = []
          @category_log.each_pair do |category, time|
            total += time
            output << "%s: %d.2ms\n" % [category, time]
          end
          output << "total: %d.2ms" % total
          <<-HTML
            <ul>
              #{output.map { |el| "<li>#{el}</li>"}}
            </ul>
          HTML
        end
  end
  private



  def list_to_accordion list
    list.map do |entry|
      if entry.children && entry.children.present?
        accordion_entry entry
      else
        "<li class='list-group-item'>#{simple_entry entry}</li>"
      end
    end.join "\n"
  end

  def simple_entry entry
    entry.to_html
  end

  def accordion_entry entry
    panel_body = list_to_accordion entry.children
    collapse_id = entry.hash.to_s
    %{
      <div class="panel-group" id="accordion-#{collapse_id}" role="tablist" aria-multiselectable="true">
        <div class="panel panel-default #{'panel-danger' if entry.duration > 100 }">
          <div class="panel-heading" role="tab" id="heading-#{collapse_id}">
            <h4 class="panel-title">
              <a data-toggle="collapse" data-parent="#accordion-#{collapse_id}" href="##{collapse_id}" aria-expanded="true" aria-controls="#{collapse_id}">
                #{ simple_entry entry }
              </a>
            </h4>
          </div>
          <div id="#{collapse_id}" class="panel-collapse collapse #{'in' if entry.duration > 100}" role="tabpanel" aria-labelledby="heading-#{collapse_id}">
            <div class="panel-body">
              #{ panel_body }
            </div>
          </div>
        </div>
      </div>
      }
  end
end
