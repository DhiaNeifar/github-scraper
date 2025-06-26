require "sorbet-runtime"

require_relative "utils"

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
    repository_document = test_connection(@repository_url)
    @is_archived = !repository_document.at_css(CSS_CLASSES["archive"]).nil?


    # is_public = nil
  end

  sig { void }
  def get_pullrequests()
    pullrequests_url = "#{@repository_url}/pulls?q="
    puts pullrequests_url
    pullrequests_document = test_connection(pullrequests_url)
    if pullrequests_document
      number_pages = get_number_pages(pullrequests_document, CSS_CLASSES["pullrequest_pagination"])
      puts number_pages
    end
  end


  """
    for page_index in 1..number_pages
      if pullrequests_page_document
        pullrequests_page_document.css(CSS_CLASSES['repository']).each do |repository_name|
          repository_name = repository_name.text.strip
          @repositories << repository_name
          repository = Repository.new(@organization, repository_name)
        end
      end
    end
  end"""

end



if __FILE__ == $0
  organization = "vercel"
  repository_name = "lua-bcrypt"
  repository = Repository.new(organization, repository_name)
  repository.get_pullrequests()
end
