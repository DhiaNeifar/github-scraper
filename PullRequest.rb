require "sorbet-runtime"
require "time"


require_relative "utils"

class PullRequest
  extend T::Sig


  sig { returns(Integer) }
  attr_accessor :number

  sig { returns(String) }
  attr_accessor :pullrequest_url

  sig { returns(String) }
  attr_accessor :title

  sig { returns(String) }
  attr_accessor :status

  sig { returns(T.nilable(Time)) }
  attr_accessor :updated_time

  sig { returns(T.nilable(Time)) }
  attr_accessor :closed_time

  sig { returns(T.nilable(Time)) }
  attr_accessor :merged_time

  sig { returns(String) }
  attr_accessor :author

  sig { returns(T.nilable(Integer)) }
  attr_accessor :additions

  sig { returns(T.nilable(Integer)) }
  attr_accessor :deletions

  sig { returns(Integer) }
  attr_accessor :changed_files

  sig { returns(Integer) }
  attr_accessor :number_commits



  sig { params(organization: String, repository_name: String, pull_number: Integer).void }
  def initialize(organization, repository_name, pull_number)
    @number = pull_number
    @pullrequest_url = "#{GITHUB_URL}/#{organization}/#{repository_name}/pull/#{@number}"

    pullrequest_document = connect(pullrequest_url)
    if pullrequest_document

      title = pullrequest_document.at_css(CSS_CLASSES["title"])
      @title = title ? title.text&.strip : ""

      status = pullrequest_document.at_css(CSS_CLASSES["status"])
      @status = status ? PRStatus.from_string(status.text.strip) : "unknown"
      puts @status

      additions = pullrequest_document.at_css(CSS_CLASSES["additions"])
      @additions = additions ? additions&.text&.strip.to_i : 0
      puts @additions

      deletions = pullrequest_document.at_css(CSS_CLASSES["deletions"])
      @deletions = deletions ? deletions&.text&.strip.to_i : 0
      puts @deletions

      all_times = pullrequest_document.css(CSS_CLASSES["relative_time"]).map { |el| Time.parse(el['datetime']) }
      @updated_time = all_times ? all_times.max : nil
      puts @updated_time

      pullrequest_document.css(CSS_CLASSES["closed_time"]).each do |item|
        if item.text.include?("closed this")
          time_element = item.at_css("relative-time")
          @closed_time = time_element ? Time.parse(time_element['datetime']) : nil
          puts @closed_time
          break
        end
      end
    end
  end
end


if __FILE__ == $0
    organization = "vercel"
    repository_name = "next.js"
    pull_number = 80956

    pullrequest = PullRequest.new(organization, repository_name, pull_number)
end
