# frozen_string_literal: true
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
require 'yaml'
require 'term/ansicolor'
require 'openssl'

OpenSSL.fips_mode = true if Gcs::Environment.ubi?

loader = Zeitwerk::Loader.for_gem
loader.push_dir(File.join(__dir__, '../ee/lib'))
loader.setup

module Gcs
  DEFAULT_REPORT_NAME = 'gl-container-scanning-report.json'
  DEFAULT_DEPENDENCY_REPORT_NAME = 'gl-dependency-scanning-report.json'

  class << self
    def root
      Pathname.new(File.expand_path('..', __dir__))
    end

    def lib
      Pathname.new(File.expand_path(__dir__, __FILE__))
    end

    def logger
      @logger ||= Logger.new($stdout)
    end

    def shell
      @shell ||= Shell.new
    end
  end
end

loader.eager_load
Gcs.logger.formatter = Gcs::LoggerFormatter.formatter
Gcs::Environment.setup
