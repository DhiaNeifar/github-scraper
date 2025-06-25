require 'sorbet-runtime'
require 'httparty'

extend T::Sig

sig { params(url: String).returns(T.nilable(HTTParty::Response)) }
def test_connection(url)
  response = HTTParty.get(url)

  if response.code.between?(200, 299)
    response
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
