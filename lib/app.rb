require "optparse"
require "concurrent-ruby"
require "logger"
require "fileutils"


require_relative "../config/environment"
require_relative "utils"


def main(options)
  # The scraping application spans over multiple phases.


  # First, logger is initialized, and the logger file is saved in ~/projact_path/log/-timestamps-.log.
  # We add the organization to organizations table. Please check the model organization in ~/project_path/app/models/organization.#!/usr/bin/env ruby -wKU


  # Instead of scraping data sequentially (Please check out previous commits for the code) that starts by scraping repository ==> pull request ==> review ==> user,
  # we divide the work into 6 phases.


  # Phase 1: We scrape all repositories sequentially. The total number of repositories is 176.

  # Phase 2: We save repositories using upsert_all (batch saving)

  # Phase 3: We loop through repositories and concurrently scrape pull requests.

  # Phase 4: We loop through pull requests and scrape users (authors of the pull requests) and we batch-save them.

  # Phase 5: We batch save the pull requests.

  # Phase 6: We scrape reviews for each pull request and batch save them.


  Rails.logger = ActiveSupport::Logger.new(STDOUT)
  logger = Rails.logger


  timestamp = Time.current.strftime('%Y%m%d_%H%M%S')
  log_path = Rails.root.join('log', "#{timestamp}.log")
  Rails.logger = ActiveSupport::Logger.new(log_path)

  organization_name = options[:org]

  Rails.logger.info("="*80)
  Rails.logger.info("[#{Time.current.strftime('%H:%M:%S')}] Starting scraping for organization: #{organization_name}")
  Rails.logger.info("="*80)

  start_time = Time.current

  organization_url = "#{GITHUB_URL}/#{organization_name}"
  Rails.logger.info("[#{Time.current.strftime('%H:%M:%S')}] Connecting to organization URL: #{organization_url}")

  organization_document = connect(logger, organization_url)

  if organization_document
    Rails.logger.info("[#{Time.current.strftime('%H:%M:%S')}] Successfully connected to organization")

    organization = Organization.find_or_initialize_by(name: organization_name)
    organization.url = organization_url
    organization.save!

    Rails.logger.info("[#{Time.current.strftime('%H:%M:%S')}] Organization saved with ID: #{organization.id}")

    fetch_repositories(organization, logger)
  else
    Rails.logger.error("[#{Time.current.strftime('%H:%M:%S')}] Failed to connect to organization URL")
  end

  total_time = (Time.current - start_time).round(2)
  Rails.logger.info("="*80)
  Rails.logger.info("[#{Time.current.strftime('%H:%M:%S')}] SCRAPING COMPLETED - Total time: #{total_time} seconds")
  Rails.logger.info("="*80)
end

def fetch_repositories(organization, logger)
  Rails.logger.info("[#{Time.current.strftime('%H:%M:%S')}] Phase 1: Extracting all repository data...")
  phase_start = Time.current

  repositories_data = extract_repositories_data(organization, logger)
  phase_time = (Time.current - phase_start).round(2)
  Rails.logger.info("[#{Time.current.strftime('%H:%M:%S')}] Phase 1 completed in #{phase_time}s - Found #{repositories_data.length} repositories")

  Rails.logger.info("[#{Time.current.strftime('%H:%M:%S')}] Phase 2: Batch saving repositories...")
  phase_start = Time.current
  saved_repositories = batch_save_repositories(organization, repositories_data, logger)
  phase_time = (Time.current - phase_start).round(2)
  Rails.logger.info("[#{Time.current.strftime('%H:%M:%S')}] Phase 2 completed in #{phase_time}s")

  Rails.logger.info("[#{Time.current.strftime('%H:%M:%S')}] Phase 3: Extracting all pull requests data...")
  phase_start = Time.current
  pull_requests_data = extract_pull_requests_data(saved_repositories, logger)
  phase_time = (Time.current - phase_start).round(2)
  Rails.logger.info("[#{Time.current.strftime('%H:%M:%S')}] Phase 3 completed in #{phase_time}s - Found #{pull_requests_data.length} total pull requests")

  Rails.logger.info("[#{Time.current.strftime('%H:%M:%S')}] Phase 4: Extracting and saving users...")
  phase_start = Time.current
  unique_users_data = extract_and_save_unique_users(pull_requests_data, logger)
  phase_time = (Time.current - phase_start).round(2)
  Rails.logger.info("[#{Time.current.strftime('%H:%M:%S')}] Phase 4 completed in #{phase_time}s - Found #{unique_users_data.length} unique users")

  Rails.logger.info("[#{Time.current.strftime('%H:%M:%S')}] Phase 5: Batch saving pull requests...")
  phase_start = Time.current
  saved_pull_requests = fill_and_save_pull_requests(pull_requests_data, logger)
  phase_time = (Time.current - phase_start).round(2)
  Rails.logger.info("[#{Time.current.strftime('%H:%M:%S')}] Phase 5 completed in #{phase_time}s")

  Rails.logger.info("[#{Time.current.strftime('%H:%M:%S')}] Phase 6: Extracting and saving reviews...")
  phase_start = Time.current
  extract_and_save_reviews(saved_pull_requests, logger)
  phase_time = (Time.current - phase_start).round(2)
  Rails.logger.info("[#{Time.current.strftime('%H:%M:%S')}] Phase 6 completed in #{phase_time}s")

  Rails.logger.info("[#{Time.current.strftime('%H:%M:%S')}] Scraping complete!")
end

def extract_repositories_data(organization, logger)

  # We loop through all possible pages (example https://github.com/orgs/vercel/repositories?page={page_index})
  # We stop when page does not contain any repository.
  # We extract repository name | url | is_public | is_archived ect...
  # We return repositories found for batch saving later.

  repositories_data = []
  page_number = 0

  loop do
    page_number += 1
    repositories_url = "#{GITHUB_URL}/orgs/#{organization.name}/repositories?page=#{page_number}"
    Rails.logger.debug("[#{Time.current.strftime('%H:%M:%S')}] Fetching repositories page #{page_number}")

    repositories_document = connect(logger, repositories_url)

    break if repositories_document.nil?

    repositories_found = repositories_document.css(CSS_CLASSES['repository'])
    break if repositories_found.empty?

    page_repositories = repositories_found.map do |repository_element|
      repository_name = repository_element.text.strip
      repository_url = "#{organization.url}/#{repository_name}"

      Rails.logger.debug("[#{Time.current.strftime('%H:%M:%S')}] Processing repository: #{repository_name}")

      repository_document = connect(logger, repository_url)
      is_archived = repository_document ? !repository_document.at_css(CSS_CLASSES["archive"]).nil? : false

      {
        name: repository_name,
        url: repository_url,
        is_public: true,
        is_archived: is_archived,
        organization_id: organization.id,
        created_at: Time.current,
        updated_at: Time.current
      }
    end

    repositories_data.concat(page_repositories)
    Rails.logger.info("[#{Time.current.strftime('%H:%M:%S')}] Extracted repositories from page #{repositories_url} (total: #{repositories_data.length})")

    # BREAK AFTER SCRAPING 10 REPOSITORIES BECAUSE IT IS TAKING TOO LONG TO TEST

    break if repositories_data.length >= 10
  end

  repositories_data
end

def batch_save_repositories(organization, repositories_data, logger)

  # We batch save the repositories found using upsert_all.

  if repositories_data.empty?
    Rails.logger.warn("[#{Time.current.strftime('%H:%M:%S')}] No repositories data to save")
    return []
  end

  Rails.logger.info("[#{Time.current.strftime('%H:%M:%S')}] Batch saving #{repositories_data.length} repositories...")

  Repository.upsert_all(
    repositories_data,
    unique_by: [:name, :organization_id],
    update_only: [:url, :is_public, :is_archived, :updated_at]
  )

  Rails.logger.info("[#{Time.current.strftime('%H:%M:%S')}] Successfully saved repositories")

  Repository.where(
    organization: organization,
    name: repositories_data.map { |repo| repo[:name] }
  ).includes(:organization)
end

def extract_pull_requests_data(repositories, logger)

  # General function to extract all pull requests of every repository.
  # We do so concurrently using threads pooling.

  Rails.logger.info("[#{Time.current.strftime('%H:%M:%S')}] Phase 3a: Collecting pull request URLs...")

  pr_urls = collect_pull_request_urls(repositories, logger)
  Rails.logger.info("[#{Time.current.strftime('%H:%M:%S')}] Found #{pr_urls.length} total pull requests to process")

  Rails.logger.info("[#{Time.current.strftime('%H:%M:%S')}] Phase 3b: Processing pull requests concurrently...")

  pull_requests_data = []
  mutex = Mutex.new
  processed_count = 0

  thread_pool = Concurrent::ThreadPoolExecutor.new(
    min_threads: 4,
    max_threads: 10,
    max_queue: pr_urls.count
  )

  futures = pr_urls.map do |pr_info|
    Concurrent::Future.execute(executor: thread_pool) do
      pr_start_time = Time.current

      pr_data = extract_pull_request_data(
        pr_info[:url],
        pr_info[:number],
        pr_info[:repository_id],
        Rails.logger,
      )

      pr_time = (Time.current - pr_start_time).round(3)

      if pr_data
        mutex.synchronize do
          pull_requests_data << pr_data
          processed_count += 1

          if processed_count % 50 == 0
            Rails.logger.info("[#{Time.current.strftime('%H:%M:%S')}] Processed #{processed_count}/#{pr_urls.length} pull requests (#{(processed_count.to_f/pr_urls.length*100).round(1)}%)")
          end
        end

        Rails.logger.debug("[#{Time.current.strftime('%H:%M:%S')}] Processed PR #{pr_info[:number]} from #{pr_info[:repository_name]} in #{pr_time}s")
      else
        Rails.logger.warn("[#{Time.current.strftime('%H:%M:%S')}] Failed to process PR #{pr_info[:number]} from #{pr_info[:repository_name]}")
      end
    end
  end

  futures.each(&:wait)
  thread_pool.shutdown

  Rails.logger.info("[#{Time.current.strftime('%H:%M:%S')}] Completed processing #{pull_requests_data.length} pull requests")
  pull_requests_data
end

def collect_pull_request_urls(repositories, logger)

  # We start by collecting pull requests urls specific to a repository.
  # pull requests page 394 associated to repository next.js url: https://github.com/vercel/next.js/pulls?page=394&q=

  pr_urls = []

  repositories.each do |repository|
    repo_start_time = Time.current
    Rails.logger.info("[#{Time.current.strftime('%H:%M:%S')}] Starting to collect PR URLs from #{repository.name}...")

    page_number = 0
    repo_pr_count = 0

    loop do
      page_number += 1
      pull_requests_url = "#{repository.url}/pulls?page=#{page_number}&q="
      pull_requests_document = connect(logger, pull_requests_url)

      break if pull_requests_document.nil?

      pull_requests_found = pull_requests_document.css(CSS_CLASSES['pull_request_box'])
      break if pull_requests_found.empty?

      page_pr_urls = pull_requests_found.map do |pull_request_box|
        pull_request_number = pull_request_box['id'].split('_').last.to_i
        pull_request_url = "#{repository.url}/pull/#{pull_request_number}"

        {
          url: pull_request_url,
          number: pull_request_number,
          repository_id: repository.id,
          repository_name: repository.name
        }
      end

      pr_urls.concat(page_pr_urls)
      repo_pr_count += page_pr_urls.length

    end

    repo_time = (Time.current - repo_start_time).round(2)
    Rails.logger.info("[#{Time.current.strftime('%H:%M:%S')}] Completed #{repository.name} - #{repo_pr_count} PRs in #{repo_time}s (total collected: #{pr_urls.length})")
  end

  pr_urls
end

def extract_pull_request_data(pull_request_url, pull_request_number, repository_id, logger)

  # We extract pull request data using its url. url example: https://github.com/vercel/ai-chatbot-svelte/pull/9
  # data extracted: title \ status \ additions \ deletions \ last_update_at \ merged_at \ closed_at \ author_name \ changed_files \ number_commits \ reviews_data
  # status can only be closed, open, merged, draft
  # if status == closed ==> closed_at is Timestamps that we extract and not nil
  # if status == merged ==> merged_at is Timestamps that we extract and not nil
  # author_name will be used later when scraping for users.

  pull_request_document = connect(logger, pull_request_url)

  unless pull_request_document
    Rails.logger.warn("[#{Time.current.strftime('%H:%M:%S')}] Failed to connect to PR #{pull_request_number} at #{pull_request_url}")
    return nil
  end

  title_element = pull_request_document.at_css(CSS_CLASSES["title"])
  title = title_element ? title_element.text&.strip : ""

  status_element = pull_request_document.at_css(CSS_CLASSES["status"])
  status = status_element ? status_element.text.strip.downcase : "unknown"

  additions_element = pull_request_document.at_css(CSS_CLASSES["additions"])
  additions = additions_element ? additions_element&.text&.strip.to_i : 0

  deletions_element = pull_request_document.at_css(CSS_CLASSES["deletions"])
  deletions = deletions_element ? deletions_element&.text&.strip.to_i : 0

  times = pull_request_document.css(CSS_CLASSES["relative_time"]).map { |el| Time.parse(el['datetime']) }
  last_update_at = times.any? ? times.max : nil

  closed_at = nil
  if status == "closed"
    pull_request_document.css(CSS_CLASSES["comments"]).each do |comment|
      if comment.text.include?("closed this")
        commented_at = comment.at_css(CSS_CLASSES["relative_time"])
        closed_at = Time.parse(commented_at['datetime']) if commented_at
        break
      end
    end
  end

  merged_at = nil
  if status == "merged"
    merged_element = pull_request_document.css(CSS_CLASSES["merged_at"]).at_css(CSS_CLASSES["relative_time"])
    merged_at = Time.parse(merged_element['datetime']) if merged_element
  end

  author_element = pull_request_document.at_css(CSS_CLASSES["author"])
  author_name = author_element ? author_element.text&.strip : nil

  number_changed_files_element = pull_request_document.at_css(CSS_CLASSES["number_changed_files"])
  changed_files = number_changed_files_element ? number_changed_files_element.text.strip.to_i : 0

  number_commits_element = pull_request_document.at_css(CSS_CLASSES["number_commits"])
  number_commits = number_commits_element ? number_commits_element.text.strip.to_i : 0

  reviews_data = extract_reviews_data(pull_request_document, pull_request_number, logger)

  Rails.logger.debug("[#{Time.current.strftime('%H:%M:%S')}] Extracted PR #{pull_request_number}: #{title} (#{status}) - #{reviews_data.length} reviews")

  {
    number: pull_request_number,
    url: pull_request_url,
    title: title,
    status: status,
    additions: additions,
    deletions: deletions,
    changed_files: changed_files,
    number_commits: number_commits,
    last_update_at: last_update_at,
    closed_at: closed_at,
    merged_at: merged_at,
    author_name: author_name,
    repository_id: repository_id,
    reviews_data: reviews_data,
    created_at: Time.current,
    updated_at: Time.current
  }
end

def extract_reviews_data(pull_request_document, pull_request_number, logger)

  # To get reviews_data, we look for comments in the pull requests.
  # If text contains "approved" ==> state "approved"
  # If text contains "requested changes" ==> state "requested changes"
  # If text contains "reviewed" ==> state "reviewed"
  # Else "unknown"

  # We also check for reviewer and the time the review was submitted.

  reviews_data = []

  reviews = pull_request_document.css(CSS_CLASSES["reviews"])
  reviews.each do |review|
    review_text = review.text.downcase
    state = if review_text.include?("approved")
              "approved"
            elsif review_text.include?("requested changes")
              "requested changes"
            elsif review_text.include?("reviewed")
              "reviewed"
            else
              "unknown"
            end

    if state != "unknown"
      reviewer_element = review.at_css("strong a.author")
      reviewer_name = reviewer_element ? reviewer_element.text.strip : nil

      submitted_at_element = review.at_css("relative-time")
      submitted_at = submitted_at_element ? Time.parse(submitted_at_element["datetime"]) : nil

      if reviewer_name && submitted_at
        reviews_data << {
          pull_request_number: pull_request_number,
          reviewer_name: reviewer_name,
          state: state,
          submitted_at: submitted_at
        }

        Rails.logger.debug("[#{Time.current.strftime('%H:%M:%S')}] Found review by #{reviewer_name} (#{state}) for PR #{pull_request_number}")
      end
    end
  end

  reviews_data
end

def extract_and_save_unique_users(pull_requests_data, logger)
  user_names = Set.new

  pull_requests_data.each do |pr_data|
    user_names.add(pr_data[:author_name]) if pr_data[:author_name]

    pr_data[:reviews_data].each do |review_data|
      user_names.add(review_data[:reviewer_name]) if review_data[:reviewer_name]
    end
  end

  Rails.logger.info("[#{Time.current.strftime('%H:%M:%S')}] Processing #{user_names.size} unique users...")

  users_data = extract_users_data(user_names.to_a, logger)

  if users_data.any?
    batch_save_users(users_data, logger)
  else
    Rails.logger.warn("[#{Time.current.strftime('%H:%M:%S')}] No user data to save")
  end

  users_data
end

def extract_users_data(user_names, logger)

  # We concurrently extarct the data of users. Same concept as extracting pull requests data.

  users_data = []
  mutex = Mutex.new
  processed_users = 0

  thread_pool = Concurrent::ThreadPoolExecutor.new(
    min_threads: 2,
    max_threads: 6,
    max_queue: user_names.length
  )

  futures = user_names.map do |user_name|
    Concurrent::Future.execute(executor: thread_pool) do
      user_data = extract_user_data(user_name, logger)

      if user_data
        mutex.synchronize do
          users_data << user_data
          processed_users += 1

          if processed_users % 20 == 0
            Rails.logger.info("[#{Time.current.strftime('%H:%M:%S')}] Processed #{processed_users}/#{user_names.length} users")
          end
        end
      end
    end
  end

  futures.each(&:wait)
  thread_pool.shutdown

  Rails.logger.info("[#{Time.current.strftime('%H:%M:%S')}] Completed processing #{users_data.length} users")
  users_data
end

def extract_user_data(author_name, logger)

  # Since we get the names of authors when scraping pull requests, we use the names to get nicknames or user login information.
  # example url: https://github.com/dhiaNeifar/ ==> we extract Dhia Neifar

  user_url = "#{GITHUB_URL}/#{author_name}"
  user_document = connect(logger, user_url)

  unless user_document
    Rails.logger.warn("[#{Time.current.strftime('%H:%M:%S')}] Failed to connect to user: #{author_name}")
    return nil
  end

  user_nickname_element = user_document.at_css(CSS_CLASSES["user_nickname"])
  user_nickname = user_nickname_element&.text&.strip
  nickname = user_nickname.presence || author_name

  Rails.logger.debug("[#{Time.current.strftime('%H:%M:%S')}] Extracted user: #{author_name} (#{nickname})")

  {
    name: author_name,
    nickname: nickname,
    url: user_url,
    created_at: Time.current,
    updated_at: Time.current
  }
end

def batch_save_users(users_data, logger)

  # We batch save the users because it is faster.

  Rails.logger.info("[#{Time.current.strftime('%H:%M:%S')}] Batch saving #{users_data.length} users...")

  User.upsert_all(
    users_data,
    unique_by: [:name],
    update_only: [:nickname, :url, :updated_at]
  )

  Rails.logger.info("[#{Time.current.strftime('%H:%M:%S')}] Successfully saved users")
end

def fill_and_save_pull_requests(pull_requests_data, logger)

  # We fill out the missing data (users because author attribute in pull request model is of type user).

  user_names = pull_requests_data.map { |pr| pr[:author_name] }.compact.uniq
  user_name_to_id = User.where(name: user_names).pluck(:name, :id).to_h

  Rails.logger.info("[#{Time.current.strftime('%H:%M:%S')}] Enriching #{pull_requests_data.length} pull requests with user IDs...")

  pull_requests_for_save = pull_requests_data.map do |pr_data|
    pr_save_data = pr_data.except(:author_name, :reviews_data)
    pr_save_data[:user_id] = user_name_to_id[pr_data[:author_name]]
    pr_save_data
  end

  Rails.logger.info("[#{Time.current.strftime('%H:%M:%S')}] Batch saving pull requests...")

  # After completing missing pull requests data, we batch save them.

  PullRequest.upsert_all(
    pull_requests_for_save,
    unique_by: [:number, :repository_id],
    update_only: [:title, :status, :additions, :deletions, :changed_files,
                  :number_commits, :last_update_at, :closed_at, :merged_at, :user_id, :updated_at]
  )

  Rails.logger.info("[#{Time.current.strftime('%H:%M:%S')}] Successfully saved pull requests")

  pull_requests_data
end

def extract_and_save_reviews(pull_requests_data, logger)

  # We complete missing information of reviews. reviews table reference both pull requests and users table.
  reviews_data = []

  pr_numbers = pull_requests_data.map { |pr| pr[:number] }.uniq
  pr_number_to_id = PullRequest.where(number: pr_numbers).pluck(:number, :id).to_h

  reviewer_names = pull_requests_data.flat_map do |pr_data|
    pr_data[:reviews_data].map { |review| review[:reviewer_name] }
  end.compact.uniq

  user_name_to_id = User.where(name: reviewer_names).pluck(:name, :id).to_h

  Rails.logger.info("[#{Time.current.strftime('%H:%M:%S')}] Preparing reviews data...")

  pull_requests_data.each do |pr_data|
    pr_data[:reviews_data].each do |review_data|
      pull_request_id = pr_number_to_id[review_data[:pull_request_number]]
      user_id = user_name_to_id[review_data[:reviewer_name]]

      if pull_request_id && user_id
        reviews_data << {
          pull_request_id: pull_request_id,
          user_id: user_id,
          state: review_data[:state],
          submitted_at: review_data[:submitted_at],
          created_at: Time.current,
          updated_at: Time.current
        }
      else
        Rails.logger.warn("[#{Time.current.strftime('%H:%M:%S')}] Missing mapping for review - PR: #{review_data[:pull_request_number]}, User: #{review_data[:reviewer_name]}")
      end
    end
  end

  if reviews_data.any?
    Rails.logger.info("[#{Time.current.strftime('%H:%M:%S')}] Batch saving #{reviews_data.length} reviews...")

    Review.upsert_all(
      reviews_data,
      unique_by: [:pull_request_id, :user_id, :submitted_at],
      update_only: [:state, :updated_at]
    )

    Rails.logger.info("[#{Time.current.strftime('%H:%M:%S')}] Successfully saved #{reviews_data.length} reviews")
  else
    Rails.logger.warn("[#{Time.current.strftime('%H:%M:%S')}] No reviews data to save")
  end
end

if __FILE__ == $0

  # Argument Parsing has been deliberately added so the user can scrape the repositories of any organization.

  options = { org: "vercel" }

  parser = OptionParser.new do |opts|
    opts.banner = "\nUsage: app.rb [options]"
    opts.separator ""
    opts.separator "This tool scrapes public repositories for a given GitHub organization."
    opts.separator "Optimized version with batch processing and PR-level threading for better performance."
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
