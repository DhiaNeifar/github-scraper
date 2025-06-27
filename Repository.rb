require "sorbet-runtime"

require_relative "utils"
require_relative "PullRequest"

class Repository
  extend T::Sig

  sig { returns(String) }
  attr_accessor :name

  sig { returns(String) }
  attr_accessor :repository_url

  sig { returns(Boolean) }
  attr_accessor :is_public

  sig { returns(Boolean) }
  attr_accessor :is_archived

  sig { returns(T::Array[PullRequest]) }
  attr_accessor :pullrequests

  sig { params(name: String, repository_url: String).void }
  def initialize(name, repository_url)

    @name = name
    @repository_url = repository_url
    @is_public = true
    @is_archived = nil
    @pullrequests = Array.new()

    # scrape

    # get_pullrequests

    # puts pullrequests.length
  end

  sig { void }
  def scrape

    repository_document = connect(@repository_url)
    @is_archived = !repository_document.at_css(CSS_CLASSES["archive"]).nil?

    pullrequests_url = "#{@repository_url}/pulls?q="
    pullrequests_document = connect(pullrequests_url)
    number_pages = get_number_pages(pullrequests_document, CSS_CLASSES["pullrequest_pagination"])

    for page_index in 1..3 # number_pages

      pullrequests_per_page_url = "#{@repository_url}/pulls?page=#{page_index}&q="
      pullrequests_page_document = connect(pullrequests_per_page_url)
      if pullrequests_page_document

        pullrequests_page_document.css(CSS_CLASSES['pullrequest_box']).each do |pullrequest_box|

          pullrequest_id = pullrequest_box['id']
          pullrequest_number = pullrequest_id.split('_').last.to_i
          pullrequest = PullRequest.new(@organization, @repository_name, @pull_number)
          @pullreuests << pullrequest

        end
      end
    end
  end
end



if __FILE__ == $0
  organization = "vercel"
  repository_name = "next.js"
  repository = Repository.new(organization, repository_name)
  repository.get_pullrequests()
end
