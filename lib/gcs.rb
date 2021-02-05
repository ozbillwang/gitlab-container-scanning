require 'ostruct'
require 'forwardable'
require 'thor'
require 'logger'
require 'open3'
require 'json'
require 'uri'
require 'date'
require 'digest'
require 'pathname'
require 'set'
require 'base64'
require 'tempfile'
require 'terminal-table'
require 'zeitwerk'

loader = Zeitwerk::Loader.for_gem
loader.setup

module Gcs
  DEFAULT_REPORT_NAME = 'gl-container-scanning-report.json'.freeze

  class << self
    def root
      Pathname.new(File.expand_path('../..', __FILE__))
    end

    def lib
      Pathname.new(File.expand_path(__dir__, __FILE__))
    end

    def logger
      @logger ||= Logger.new(STDOUT)
    end

    def shell
      @shell ||= Shell.new
    end
  end
end

loader.eager_load
Gcs.logger.formatter = Gcs::LoggerFormatter.formatter
Gcs::Environment.setup_log_level
