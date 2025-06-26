require "sorbet-runtime"

require_relative "utils"
require_relative "PullRequest"

class Repository
  extend T::Sig

  sig { returns(String) }
  attr_accessor :organization

  sig { returns(String) }
  attr_accessor :name

  sig { returns(Boolean) }
  attr_accessor :is_public

  sig { returns(Boolean) }
  attr_accessor :is_archived

  sig { params(organization: String, repository_name: String).void }
  def initialize(organization, repository_name)
    @organization = organization
    @name = repository_name

    @repository_url = "#{GITHUB_URL}/#{@organization}/#{@name}"
    repository_document = connect(@repository_url)
    @is_archived = !repository_document.at_css(CSS_CLASSES["archive"]).nil?


    # is_public = nil
  end

  sig { void }
  def get_pullrequests()
    pullrequests_url = "#{@repository_url}/pulls?q="
    pullrequests_document = connect(pullrequests_url)
    if pullrequests_document
      number_pages = get_number_pages(pullrequests_document, CSS_CLASSES["pullrequest_pagination"])
      for page_index in 1..3
        pullrequests_per_page_url = "#{@repository_url}/pulls?page=#{page_index}&q="

        pullrequests_page_document = connect(pullrequests_per_page_url)
        if pullrequests_page_document
          pullrequests_page_document.css(CSS_CLASSES['pullrequest_box']).each do |pullrequest_box|
            pullrequest_id = pullrequest_box['id']
            pullrequest_number = pullrequest_id.split('_').last.to_i
            pullrequest = PullRequest.new(@organization, @repository_name, @pull_number)
          end
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
