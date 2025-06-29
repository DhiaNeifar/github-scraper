# lib/scraper_logger.rb

require 'fileutils'
require 'logger'

class MyLogger
  attr_reader :file_logger, :console_logger

  def initialize
    log_dir = Rails.root.join('log', 'scraper_logs')

    timestamp = Time.current.strftime('%Y%m%d_%H%M%S')
    log_file_path = Rails.root.join("log/#{timestamp}.log")

    @file_logger = Logger.new(log_file_path)
    @file_logger.level = Logger::INFO
    @file_logger.formatter = formatter

    @console_logger = Logger.new(STDOUT)
    @console_logger.level = Logger::INFO
    @console_logger.formatter = formatter
  end

  def info(message)
    log(:info, message)
  end

  def error(message)
    log(:error, message)
  end

  def warn(message)
    log(:warn, message)
  end

  private

  def log(level, message)
    @file_logger.send(level, message)
    @console_logger.send(level, message)
  end

  def formatter
    proc do |severity, datetime, progname, msg|
      "[#{datetime.strftime('%Y-%m-%d %H:%M:%S')}] #{severity}: #{msg}\n"
    end
  end
end
