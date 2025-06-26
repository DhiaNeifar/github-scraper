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

      additions = pullrequest_document.at_css(CSS_CLASSES["additions"])
      @additions = additions ? additions&.text&.strip.to_i : 0

      deletions = pullrequest_document.at_css(CSS_CLASSES["deletions"])
      @deletions = deletions ? deletions&.text&.strip.to_i : 0

      all_times = pullrequest_document.css(CSS_CLASSES["relative_time"]).map { |el| Time.parse(el['datetime']) }
      @updated_time = all_times ? all_times.max : nil

      @closed_time = nil
      if @status == PRStatus::Closed
        pullrequest_document.css(CSS_CLASSES["comments"]).each do |comment|
          if comment.text.include?("closed this")
            comment_time = comment.at_css(CSS_CLASSES["relative_time"])
            @closed_time = Time.parse(comment_time['datetime']) if comment_time
            break
          end
        end
      end

      @merged_time = nil
      if @status == PRStatus::Merged
        merged_time = pullrequest_document.css(CSS_CLASSES["merged_time"]).at_css(CSS_CLASSES["relative_time"])
        @merged_time = Time.parse(merged_time['datetime']) if merged_time
      end

      author = pullrequest_document.at_css(CSS_CLASSES["author"])
      @author = author ? author.text&.strip : ""

      number_changed_files = pullrequest_document.at_css(CSS_CLASSES["number_changed_files"])
      @changed_files = number_changed_files ? number_changed_files.text.strip.to_i : 0

      number_commits = pullrequest_document.at_css(CSS_CLASSES["number_commits"])
      @number_commits = number_commits ? number_commits.text.strip.to_i : 0

      print_summary
    end
  end

  sig { void }
  def print_summary
    puts "Pull Request ##{@number}"
    puts "URL: #{@pullrequest_url}"
    puts "Title: #{@title}"
    puts "Status: #{@status}"
    puts "Updated Time: #{@updated_time}"
    puts "Closed Time: #{@closed_time}"
    puts "Merged Time: #{@merged_time}"
    puts "Author: #{@author}"
    puts "Additions: #{@additions}"
    puts "Deletions: #{@deletions}"
    puts "Changed Files: #{@changed_files}"
    puts "Number of Commits: #{@number_commits}"
  end
end


if __FILE__ == $0
    organization = "vercel"
    repository_name = "next.js"
    pull_number = 80716

    pullrequest = PullRequest.new(organization, repository_name, pull_number)
end
