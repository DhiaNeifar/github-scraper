require "sorbet-runtime"
require "nokogiri"


require_relative "utils"
require_relative "Repository"


class Scraper
  extend T::Sig

  sig { returns(String) }
  attr_accessor :organization

  sig { returns(String) }
  attr_accessor :organization_url

  sig { returns(T::Array[String]) }
  attr_accessor :repositories

  sig { params(organization: String).void }
  def initialize(organization)
    @organization = organization

    #Urls
    @organization_url = "#{GITHUB_URL}/orgs/#{@organization}"
    @repositories_url = "#{organization_url}/repositories"

    @repositories = Array.new()
  end

  sig { void }
  def scrape
    repositories_document = connect(@repositories_url)
    if repositories_document
      number_pages = get_number_pages(repositories_document, CSS_CLASSES["repository_pagination"])
      puts number_pages
      # get_repositories(number_pages)

      # puts @repositories.length
    else
      puts "Failed to fetch repositories."
    end
  end


  sig { params(number_pages: Integer).void }
  def get_repositories(number_pages)
    for page_index in 1..number_pages
      repositories_per_page_url = "#{@repositories_url}?page=#{page_index}"
      repositories_page_document = connect(repositories_per_page_url)
      if repositories_page_document
        repositories_page_document.css(CSS_CLASSES['repository']).each do |repository_name|
          repository_name = repository_name.text.strip
          @repositories << repository_name
          repository = Repository.new(@organization, repository_name)
        end
      end
    end
  end
end
