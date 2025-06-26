require "sorbet-runtime"
require "time"


class PullRequest
  extend T::Sig


  sig { returns(Integer) }
  attr_accessor :number

  sig { returns(String) }
  attr_accessor :title

  sig { returns(T.nilable(Time)) }
  attr_accessor :updated_time

  sig { returns(T.nilable(Time)) }
  attr_accessor :closed_time

  sig { returns(T.nilable(Time)) }
  attr_accessor :merged_time

  sig { returns(String) }
  attr_accessor :author

  sig { returns(Integer) }
  attr_accessor :additions

  sig { returns(Integer) }
  attr_accessor :deletions

  sig { returns(Integer) }
  attr_accessor :changed_files

  sig { returns(Integer) }
  attr_accessor :number_commits



  sig { params(organization: String, repository_name: String, pull_number: Integer).void }
  def initialize(organization, repository_name, pull_number)
    @organization = organization
    @repository_name = repository_name
    @number = pull_number

    number

  end
end

if __FILE__ == $0
    organization = "vercel"
    repository_name = "xterm.js"

    repository = Repository.new(organization, repository_name)
end
