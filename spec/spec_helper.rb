$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'rubygems'
require 'cimpress_mcp/cli'

require 'bundler'
Bundler.setup

RSpec.configure do |c|
end

