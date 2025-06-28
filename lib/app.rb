require "optparse"

require_relative "../config/environment"
require_relative "utils"


def main(options)
  organization_name = options[:org]

  organization_url = "#{GITHUB_URL}/#{organization_name}"
  organization_document = connect(organization_url)

  if organization_document

    organization = Organization.find_or_initialize_by(name: organization_name)
    organization.url = organization_url
    organization.save!

    fetch_repositories(organization)

  end

end


def fetch_repositories(organization)

  page_number = 0

  loop do

    page_number += 1
    repositories_url = "#{GITHUB_URL}/orgs/#{organization.name}/repositories?page=#{page_number}"
    repositories_document = connect(repositories_url)

    break if repositories_document.nil?

    repositories_found = repositories_document.css(CSS_CLASSES['repository'])
    break if repositories_found.empty?

    repositories_found.each do |repository_name|

      repository_name = repository_name.text.strip
      repository_url = "#{organization.url}/#{repository_name}"

      puts repository_url

      is_archived = false
      is_public = true

      repository = Repository.find_or_initialize_by(
        name: repository_name,
        organization: organization
      )

      repository.url = repository_url
      repository.is_public = is_public

      repository_document = connect(repository.url)
      if repository_document

        repository.is_archived = !repository_document.at_css(CSS_CLASSES["archive"]).nil?

      end

      repository.save! if repository.changed?

      fetch_pull_requests(repository)

    end

  end

end


def fetch_pull_requests(repository)

    pull_requests = Array.new()
    page_number = 0

    loop do

      page_number += 1
      pull_requests_url = "#{repository.url}/pulls?page=#{page_number}&q="
      pull_requests_document = connect(pull_requests_url)

      break if pull_requests_document.nil?

      pull_requests_found = pull_requests_document.css(CSS_CLASSES['pull_request_box'])

      break if pull_requests_found.empty?

      pull_requests_found.each do |pull_request_box|

        pull_request_number = pull_request_box['id'].split('_').last.to_i

        pull_request_url = "#{repository.url}/pull/#{pull_request_number}"

        pull_request = PullRequest.find_or_initialize_by(
          number: pull_request_number,
          url: pull_request_url,
          repository: repository
        )

        fetch_pull_request(pull_request)

        pull_request.save! if pull_request.changed?

        pull_requests << pull_request

      end

    end
    puts "For repository #{repository.name}, we found #{pull_requests.length} pull requests."
end



def fetch_pull_request(pull_request)

  pull_request_document = connect(pull_request.url)

  if pull_request_document

    title = pull_request_document.at_css(CSS_CLASSES["title"])
    pull_request.title = title ? title.text&.strip : ""

    status = pull_request_document.at_css(CSS_CLASSES["status"])
    pull_request.status = status ? status.text.strip.downcase : "unknown"

    additions = pull_request_document.at_css(CSS_CLASSES["additions"])
    pull_request.additions = additions ? additions&.text&.strip.to_i : 0

    deletions = pull_request_document.at_css(CSS_CLASSES["deletions"])
    pull_request.deletions = deletions ? deletions&.text&.strip.to_i : 0

    all_times = pull_request_document.css(CSS_CLASSES["relative_time"]).map { |el| Time.parse(el['datetime']) }
    pull_request.last_update_at = all_times ? all_times.max : nil

    pull_request.closed_at = nil
    if pull_request.status == "closed"

      pull_request_document.css(CSS_CLASSES["comments"]).each do |comment|

        if comment.text.include?("closed this")

          commented_at = comment.at_css(CSS_CLASSES["relative_time"])
          pull_request.closed_at = Time.parse(commented_at['datetime']) if commented_at
          break

        end

      end

    end

    merged_at = nil
    if pull_request.status == "merged"

      merged_at = pull_request_document.css(CSS_CLASSES["merged_at"]).at_css(CSS_CLASSES["relative_time"])
      pull_request.merged_at = Time.parse(merged_at['datetime']) if merged_at

    end

    author = pull_request_document.at_css(CSS_CLASSES["author"])
    pull_request.user = author ? fetch_user(author.text&.strip) : nil

    number_changed_files = pull_request_document.at_css(CSS_CLASSES["number_changed_files"])
    pull_request.changed_files = number_changed_files ? number_changed_files.text.strip.to_i : 0

    number_commits = pull_request_document.at_css(CSS_CLASSES["number_commits"])
    pull_request.number_commits = number_commits ? number_commits.text.strip.to_i : 0

    fetch_reviews(pull_request, pull_request_document)

  end

end

def fetch_user(author)

  user_url = "#{GITHUB_URL}/#{author}"
  user_document = connect(user_url)

  user_nickname = nil

  if user_document
    user_nickname = user_document.at_css(CSS_CLASSES["user_nickname"])&.text&.strip
  end

  nickname = user_nickname.presence || author

  user = User.find_or_initialize_by(
    name: author,
    url: user_url
  )
  user.nickname = nickname

  user.save! if user.changed?

  return user
end


def fetch_reviews(pull_request, pull_request_document)

  reviews = pull_request_document.css(CSS_CLASSES["reviews"])
  reviews.each do |review|

    review_text = review.text.downcase
    state =
      if review_text.include?("approved")
        "approved"
      elsif review_text.include?("requested changes")
        "requested changes"
      elsif review_text.include?("reviewed")
        "reviewed"
      else
        "unknown"
      end

    if state != "unknown"

      reviewer = review.at_css("strong a.author")
      reviewer = reviewer ? fetch_user(reviewer.text.strip) : nil


      submitted_at = review.at_css("relative-time")
      submitted_at = submitted_at ? Time.parse(submitted_at["datetime"]) : nil

      review = Review.find_or_initialize_by(
        pull_request: pull_request,
        user: reviewer,
        state: state,
        submitted_at: submitted_at
      )

      review.save! if review.changed?

    end

  end

end



if __FILE__ == $0

  options = { org: "vercel" }

  parser = OptionParser.new do |opts|

    opts.banner = "\nUsage: scraper.rb [options]"
    opts.separator ""
    opts.separator "This tool scrapes public repositories for a given GitHub organization."
    opts.separator "You can specify the organization name, or use the default: 'vercel'."
    opts.separator ""
    opts.separator "Options:"

    opts.on("--org=ORG", "GitHub organization (default: vercel)") do |org|

      options[:org] = org

    end

    opts.on("-h", "--help", "Prints this help message") do

      puts opts
      exit

    end

  end

  parser.parse!
  main(options)

end
