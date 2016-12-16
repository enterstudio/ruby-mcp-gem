require 'spec_helper'
require 'Cimpress_mcp'

describe Cimpress_mcp::Client do

  describe "health checks" do
    it "should be able to check the health of all MCP services" do
      print "Username: "
      username = STDIN.gets().chomp
      print "Password: "
      password = STDIN.noecho(&:gets).chomp
      puts
      client = Cimpress_mcp::Client.new(username: username, password: password )
      client.health_checks
    end
  end

  describe "configuration" do
    it "should have configuration data " do
      puts "This is like, totally checking to see if the CLI is reading its configuration data successfully."
    end
  end

end