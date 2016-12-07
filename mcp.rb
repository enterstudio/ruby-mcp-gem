require 'optparse'
require 'io/console'
require 'prawn'
require 'tmpdir'
require 'securerandom'

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
	puts
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
when 'create_doc'
	tmpfile = Dir::Tmpname.make_tmpname(['MCPDOC', '.pdf'], nil)
	Prawn::Document.generate(tmpfile, :page_size => "C8",:page_layout => :landscape, :margin => 0) do
		stroke_circle [0, 0], 10
		bounding_box([25, bounds.height-25], :width => bounds.width-50, :height => bounds.height-50) do
			stroke_axis(:negative_axes_length => 15, :step_length => 50)
			stroke_circle [0, 0], 10
			text "Hello MCP!"
		end
	end
	upload = mcp.upload_file(file: File.new(tmpfile))
	File.delete(tmpfile)
	puts upload['uploadId']
else
    puts 'unknown command'
end
