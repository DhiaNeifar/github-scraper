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

    scrape

    # get_pullrequests

    # puts pullrequests.length
  end

  sig { void }
  def scrape

    repository_document = connect(@repository_url)
    if repository_document

      @is_archived = !repository_document.at_css(CSS_CLASSES["archive"]).nil?

    end

    pullrequests_url = "#{@repository_url}/pulls?q="
    pullrequests_document = connect(pullrequests_url)
    if pullrequests_document

      number_pages = get_number_pages(pullrequests_document, CSS_CLASSES["pullrequest_pagination"])

      for page_index in 1..number_pages

        pullrequests_per_page_url = "#{@repository_url}/pulls?page=#{page_index}&q="
        pullrequests_page_document = connect(pullrequests_per_page_url)
        if pullrequests_page_document

          pullrequests_page_document.css(CSS_CLASSES['pullrequest_box']).each do |pullrequest_box|

            pullrequest_id = pullrequest_box['id']
            pullrequest_number = pullrequest_id.split('_').last.to_i

            pullrequest_url = "#{@repository_url}/pull/#{pullrequest_number}"
            print "\nPull Request #{pullrequest_number} \n"
            pullrequest = PullRequest.new(pullrequest_url, pullrequest_number)
            @pullrequests << pullrequest

          end
        end
      end
    end
  end
end



if __FILE__ == $0
  organization = "vercel"
  repository_name = "next.js"
  repository_url = "#{GITHUB_URL}/#{organization}/#{repository_name}"
  repository = Repository.new(repository_name, repository_url)
  puts "Total number of pull requests: #{repository.pullrequests.length}"
end
