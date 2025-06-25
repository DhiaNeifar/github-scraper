require 'optparse'

require_relative "Scraper"


def main(options)
  scraper = Scraper.new(options[:org])

  scraper.scrape()
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
