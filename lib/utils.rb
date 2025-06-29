require "httparty"
require "nokogiri"
require "active_record"
require "yaml"
require "erb"
require "dotenv/load"


GITHUB_URL = "https://github.com"

CSS_CLASSES = {
  "repository" => ".ListItem-module__listItem--kHali .Title-module__anchor--SyQM6 span",
  "archive" => ".flash.flash-warn.flash-full.border-top-0.text-center.text-bold.py-2",
  "pull_request_box" => ".Box-row.Box-row--focus-gray.p-0.mt-0.js-navigation-item.js-issue-row",
  "title" => ".js-issue-title.markdown-title",
  "additions" => "#diffstat .color-fg-success",
  "deletions" => "#diffstat .color-fg-danger",
  "status" => ".flex-shrink-0.mb-2.flex-self-start.flex-md-self-center span.State",
  "relative_time" => "relative-time",
  "comments" => ".TimelineItem-body",
  "merged_at" => "div.d-flex.flex-items-center.flex-wrap.mt-0.gh-header-meta div.flex-auto.min-width-0.mb-2 relative-time",
  "author" => ".author.Link--secondary.text-bold.css-truncate.css-truncate-target.expandable",
  "number_changed_files" => "#files_tab_counter",
  "number_commits" => "#commits_tab_counter",
  "reviews" => ".TimelineItem-body.d-flex.flex-column.flex-md-row.flex-justify-start div.flex-auto.flex-md-self-center",
  "user_nickname" => ".p-name.vcard-fullname.d-block.overflow-hidden"
}

def connect(logger, url, timeout = 1)

  loop do

    response = HTTParty.get(url)

    case response.code

    when 200..299

      return Nokogiri::HTML(response.body)

    when 429

      logger.error("Error 429: Too Many Requests for #{url} => Rate limited. Sleeping for #{timeout} seconds...")
      sleep(timeout)
      timeout *= 2

    else

      logger.error("[#{Time.current.strftime('%H:%M:%S')}] Request failed with status code to #{url}: #{response.code}")
      return nil

    end

  end

rescue SocketError => e

  logger.error("[#{Time.current.strftime('%H:%M:%S')}] Network error to #{url}: #{e.message}")
  return nil

rescue StandardError => e

  logger.error("[#{Time.current.strftime('%H:%M:%S')}] Unexpected error to #{url}: #{e.message}")
  return nil

end


def get_number_pages(document, css_class)

  elements = document.css(css_class)
  numbers = elements.flat_map do |el|

    sources = [el.text, el['aria-label'], el['data-total-pages']].compact
    sources.flat_map { |txt| txt.scan(/\d+/).map(&:to_i) }

  end

  numbers.max || 1

end
