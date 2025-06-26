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
    @repositories_url = @organization_url + "/repositories"

    @repositories = Array.new()
  end

  sig { void }
  def scrape
    main_document = test_connection(@repositories_url)
    if main_document
      number_pages = get_number_pages(main_document)
      get_repositories(number_pages)

      puts @repositories.length
    else
      puts "Failed to fetch repositories."
    end
  end

  sig { params(document: Nokogiri::HTML::Document).returns(Integer)}
  def get_number_pages(document)
    css_code = 'a.prc-Pagination-Page-yoEQf'
    page_links = document.css(css_code)
    page_numbers = page_links.map { |element| element.text.strip.to_i }
    page_numbers.max
  end



  sig { params(number_pages: Integer).void }
  def get_repositories(number_pages)

    css_code = '.ListItem-module__listItem--kHali .Title-module__anchor--SyQM6 span'
    for page_index in 1..number_pages
      repositories_per_page_url = @repositories_url + "?page=#{page_index}"
      repositories_page_document = test_connection(repositories_per_page_url)
      if repositories_page_document
        repositories_page_document.css(css_code).each do |repository_name|
          repository_name = repository_name.text.strip
          @repositories << repository_name
          repository = Repository.new(@organization, repository_name)
        end
      end
    end
  end
end
