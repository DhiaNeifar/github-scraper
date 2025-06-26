require 'sorbet-runtime'
require 'httparty'

GITHUB_URL = "https://github.com"

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
