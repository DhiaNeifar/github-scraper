require "sorbet-runtime"
require "time"


require_relative "utils"
require_relative "Enums"
require_relative "User"
require_relative "Review"


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
  attr_accessor :updated_at

  sig { returns(T.nilable(Time)) }
  attr_accessor :closed_at

  sig { returns(T.nilable(Time)) }
  attr_accessor :merged_at

  sig { returns(User) }
  attr_accessor :author

  sig { returns(T.nilable(Integer)) }
  attr_accessor :additions

  sig { returns(T.nilable(Integer)) }
  attr_accessor :deletions

  sig { returns(Integer) }
  attr_accessor :changed_files

  sig { returns(Integer) }
  attr_accessor :number_commits

  sig { returns(T::Arrar[Review]) }
  attr_accessor :reviews



  sig { params(pullrequest_url: String, pull_number: Integer).void }
  def initialize(pullrequest_url, pull_number)

    @number = pull_number
    @pullrequest_url = pullrequest_url
    @reviews = Array.new()

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

      @closed_at = nil
      if @status == PRStatus::Closed

        pullrequest_document.css(CSS_CLASSES["comments"]).each do |comment|

          if comment.text.include?("closed this")

            commented_at = comment.at_css(CSS_CLASSES["relative_time"])
            @closed_at = Time.parse(commented_at['datetime']) if commented_at
            break

          end

        end

      end

      @merged_at = nil
      if @status == PRStatus::Merged

        merged_at = pullrequest_document.css(CSS_CLASSES["merged_at"]).at_css(CSS_CLASSES["relative_time"])
        @merged_at = Time.parse(merged_at['datetime']) if merged_at

      end

      author = pullrequest_document.at_css(CSS_CLASSES["author"])
      @author = author ? User.new(author.text&.strip) : nil

      number_changed_files = pullrequest_document.at_css(CSS_CLASSES["number_changed_files"])
      @changed_files = number_changed_files ? number_changed_files.text.strip.to_i : 0

      number_commits = pullrequest_document.at_css(CSS_CLASSES["number_commits"])
      @number_commits = number_commits ? number_commits.text.strip.to_i : 0

      reviews = pullrequest_document.css(CSS_CLASSES["reviews"])
      reviews.each do |review|

        review_text = review.text.downcase
        state =
          if review_text.include?("approved")
            ReviewState::Approved
          elsif review_text.include?("requested changes")
            ReviewState::ChangesRequested
          elsif review_text.include?("reviewed")
            ReviewState::Reviewed
          else
            ReviewState::Unknown
          end

        if state != ReviewState::Unknown

          reviewer = review.at_css("strong a.author")
          reviewer = reviewer ? User.new(reviewer.text.strip) : nil

          submitted_at = review.at_css("relative-time")
          submitted_at = submitted_at ? Time.parse(submitted_at["datetime"]) : nil

          @reviews << Review.new(reviewer, state, submitted_at)

        end

      end

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
    puts "Author: #{@author.name}"
    puts "Additions: #{@additions}"
    puts "Deletions: #{@deletions}"
    puts "Changed Files: #{@changed_files}"
    puts "Number of Commits: #{@number_commits}"
    puts "Number of Reviews: #{@reviews.length}"

  end

end


if __FILE__ == $0
    organization = "vercel"
    repository_name = "next.js"
    pull_number = 80732
    pullrequest_url = "#{GITHUB_URL}/#{organization}/#{repository_name}/pull/#{pull_number}"
    puts pullrequest_url
    pullrequest = PullRequest.new(pullrequest_url, pull_number)
end
