require "sorbet-runtime"
require "httparty"
require "nokogiri"

GITHUB_URL = "https://github.com"

CSS_CLASSES = {
  "repository_pagination" => "a.prc-Pagination-Page-yoEQf",
  "pullrequest_pagination" => ".paginate-container.d-none.d-sm-flex.flex-sm-justify-center",
  "repository" => ".ListItem-module__listItem--kHali .Title-module__anchor--SyQM6 span",
  "archive" => ".flash.flash-warn.flash-full.border-top-0.text-center.text-bold.py-2"
}


extend T::Sig

sig { params(url: String).returns(T.nilable(Nokogiri::HTML::Document)) }
def test_connection(url)
  response = HTTParty.get(url)

  if response.code.between?(200, 299)
    document = Nokogiri::HTML(response.body)
    document
  else
    puts "Request failed with status code: #{response.code}"
    nil
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
