require 'sorbet-runtime'
require 'nokogiri'
require_relative 'utils'

class Scraper
  extend T::Sig

  sig { returns(String) }
  attr_accessor :organization

  sig { returns(String) }
  attr_accessor :github_url

  sig { returns(String) }
  attr_accessor :organization_url

  sig { returns(T::Array[String]) }
  attr_accessor :repositories

  sig { params(organization: String, github_url: String).void }
  def initialize(organization, github_url = "https://github.com")
    @organization = organization
    @github_url = github_url
    @organization_url = "#{@github_url}/orgs/#{@organization}/repositories"
    @repositories = Array.new()
  end

  sig { void }
  def scrape
    response = test_connection(@organization_url)
    if response
      document = Nokogiri::HTML(response.body)
      get_repositories(document)
      puts @repositories
    else
      puts "Failed to fetch repositories."
    end
  end

  sig { params(document: Nokogiri::HTML::Document).void }
  def get_repositories(document)
    css_code = '.ListItem-module__listItem--kHali .Title-module__anchor--SyQM6 span'
    document.css(css_code).each do |el|
      @repositories << el.text.strip
    end
  end
end
