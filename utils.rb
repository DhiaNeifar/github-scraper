require "sorbet-runtime"
require "httparty"
require "nokogiri"


extend T::Sig


GITHUB_URL = "https://github.com"

CSS_CLASSES = {
  "repository_pagination" => "a.prc-Pagination-Page-yoEQf",
  "pullrequest_pagination" => ".paginate-container.d-none.d-sm-flex.flex-sm-justify-center",
  "repository" => ".ListItem-module__listItem--kHali .Title-module__anchor--SyQM6 span",
  "archive" => ".flash.flash-warn.flash-full.border-top-0.text-center.text-bold.py-2",
  "pullrequest_box" => ".Box-row.Box-row--focus-gray.p-0.mt-0.js-navigation-item.js-issue-row",
  "title" => ".js-issue-title.markdown-title",
  "additions" => "#diffstat .color-fg-success",
  "deletions" => "#diffstat .color-fg-danger",
  "status" => ".flex-shrink-0.mb-2.flex-self-start.flex-md-self-center span.State",
  "relative_time" => "relative-time",
  "comments" => ".TimelineItem-body",
  "merged_time" => "div.d-flex.flex-items-center.flex-wrap.mt-0.gh-header-meta div.flex-auto.min-width-0.mb-2 relative-time",
  "author" => ".author.Link--secondary.text-bold.css-truncate.css-truncate-target.expandable",
  "number_changed_files" => "#files_tab_counter",
  "number_commits" => "#commits_tab_counter",
}

class PRStatus < T::Enum
  enums do
    Open    = new
    Closed  = new
    Merged  = new
    Draft   = new
    Unknown = new
  end

  STATUS_MAP = {
    "open"   => Open,
    "closed" => Closed,
    "merged" => Merged,
    "draft"  => Draft
  }

  def self.from_string(raw)
    STATUS_MAP[raw.strip.downcase] || Unknown
  end
end



sig { params(url: String, rate_limiter: Integer).returns(T.nilable(Nokogiri::HTML::Document)) }
def connect(url, rate_limiter = 1)
  loop do
    response = HTTParty.get(url)

    case response.code
    when 200..299
      return Nokogiri::HTML(response.body)
    when 429
      puts "Error 429: Too Many Requests => Rate limited. Sleeping for #{rate_limiter} seconds..."
      sleep(rate_limiter)
      rate_limiter *= 2
    else
      puts "Request failed with status code: #{response.code}"
      return nil
    end
  end
rescue SocketError => e
  puts "Network error: #{e.message}"
  nil
rescue StandardError => e
  puts "Unexpected error: #{e.message}"
  nil
end



sig { params(document: Nokogiri::HTML::Document, css_class: String).returns(Integer) }
def get_number_pages(document, css_class)
  elements = document.css(css_class)

  numbers = elements.flat_map do |el|
    # Pull from text and known attributes
    sources = [el.text, el['aria-label'], el['data-total-pages']].compact

    sources.flat_map { |txt| txt.scan(/\d+/).map(&:to_i) }
  end

  numbers.max || 1
end
