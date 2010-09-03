require "rubygems"
require "logger"
require 'active_record'
require 'active_support'
require "spec"
require "rack/test"
require 'rack'
require File.dirname(__FILE__) + '/../lib/active_ext_api'
require "pp"

plugin_spec_dir = File.dirname(__FILE__)

RAILS_ENV = 'test'
ActiveRecord::Base.logger = Logger.new(plugin_spec_dir + "/debug.log")

unless defined?(Rails)
	Rails = OpenStruct.new
	Rails.logger = ActiveRecord::Base.logger
end

test_db_file = File.join(plugin_spec_dir, 'db', 'test.sqlite3')
File.unlink(test_db_file) if File.exist?(test_db_file)
ActiveRecord::Base.establish_connection(
  "adapter" => "sqlite3", "database" => test_db_file
)
load(plugin_spec_dir + '/db/schema.rb')
require plugin_spec_dir + '/fixtures/models.rb'

