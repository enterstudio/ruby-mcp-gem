require 'optparse'
require 'io/console'

require_relative "CimpressMCP.rb"

options = {}
optparse = OptionParser.new do |opts|
	opts.on('-u', '--username USERNAME', 'cimpress open username') do |user|
		options[:user] = user
	end
	opts.on('-t', '--token REFRESH_TOKEN', 'refresh token') do |refresh_token|
		options[:refresh_token] = refresh_token
	end
	opts.on('-m', '--mode MODE', 'command mode - operation to run') do |mode|
		options[:mode] = mode
	end
end
optparse.parse!

if options[:user]
	print "Password: "
	password = STDIN.noecho(&:gets).chomp
	mcp = CimpressMCP::Client.new(username: options[:user], password: password )
elsif options[:refresh_token]
	mcp = CimpressMCP::Client.new(refresh_token: options[:refresh_token])
else
	"Require either a refresh token or a username and password"
end

case options[:mode]
when 'list_products'
    mcp.list_products.each { |product|
		puts "#{product['Sku']}: #{product['ProductName']}"
	}
else
    puts 'unknown command'
end
