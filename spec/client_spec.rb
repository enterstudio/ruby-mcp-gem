require 'spec_helper'
require 'Cimpress_mcp'

describe Cimpress_mcp::Client do

  before :all do
    print "Username: "
    username = STDIN.gets().chomp
    print "Password: "
    password = STDIN.noecho(&:gets).chomp
    puts

    @client = Cimpress_mcp::Client.new(username: username, password: password )
  end

  describe "health checks" do
    it "should be able to check the health of all MCP services" do
      @client.health_checks
    end
  end

  describe "configuration" do
    it "should have configuration data " do
        #For now, we'll just verify that one random portion of the config class isn't null.
        expect(Cimpress_mcp::SERVICES[:rasterization][:endpoint_url]).should_not eq(nil)
    end
  end

end