require 'thor'
require 'console'
require 'open3'
require 'json'
require 'digest'
require 'zeitwerk'

loader = Zeitwerk::Loader.for_gem
loader.setup

module Gcs
 class << self
   def self.root
     Pathname.new(File.dirname(__FILE__)).join('../..')
   end

   def logger
     @logger ||= Console.logger
   end

   def shell
     @shell ||= Shell.new
   end
 end
end

# loader.eager_load
