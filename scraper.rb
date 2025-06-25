require 'sorbet-runtime'

class Scraper
  extend T::Sig


  sig { returns(String) }
  attr_accessor :organization

  sig { returns(String) }
  attr_accessor :github_url

  sig { returns(String) }
  attr_accessor :organization_url


  sig { params(organization: String, github_link: String).void }
  def initialize(organization, github_url = "https://github.com")
    @organization = organization
    @github_url = github_url
    @organization_url = @github_url + '/' + @organization
  end

  sig { void }
  def scrape
    puts 'hola'
  end
end





if __FILE__ == $0
  puts
end
