require "sorbet-runtime"
require "nokogiri"


require_relative "utils"
require_relative "Repository"


class Organization
  extend T::Sig

  sig { returns(String) }
  attr_accessor :name

  sig { returns(String) }
  attr_accessor :organization_url

  sig { returns(T::Array[Repository]) }
  attr_accessor :repositories


  sig { params(name: String).void }
  def initialize(name)

    @organization_url = "#{GITHUB_URL}/orgs/#{name}"
    @name = name
    @repositories_url = "#{@organization_url}/repositories"
    @repositories = Array.new()

    scrape

  end

  sig { void }
  def scrape

    repositories_document = connect(@repositories_url)
    number_pages = get_number_pages(repositories_document, CSS_CLASSES["repository_pagination"])
    get_repositories(number_pages)

  end

  sig { params(number_pages: Integer).void }
  def get_repositories(number_pages)

    for page_index in 1..1 # number_pages

      repositories_per_page_url = "#{@repositories_url}?page=#{page_index}"
      repositories_page_document = connect(repositories_per_page_url)

      if repositories_page_document

        repositories_page_document.css(CSS_CLASSES['repository']).each do |repository|

          repository = repository.text.strip
          repository_url = "#{GITHUB_URL}/#{@name}/#{repository}"
          repository = Repository.new(repository, repository_url)
          @repositories << repository

        end
      end
    end
  end
end

if __FILE__ == $0
  organization = Organization.new("vercel")
  puts organization.repositories.length
end
