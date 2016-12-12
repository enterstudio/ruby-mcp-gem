require 'optparse'
require 'io/console'
require 'prawn'
require 'tmpdir'
require 'uri'
require 'CimpressMCP'

#Creates an example pdf document and fills it with random content.
def create_example_pdf
	tmpfile = Dir::Tmpname.make_tmpname(['MCPDOC', '.pdf'], nil)
	Prawn::Document.generate(tmpfile, :page_size => "A6",:page_layout => :landscape, :margin => 0) do
		stroke_circle [0, 0], 10
		bounding_box([25, bounds.height-25], :width => bounds.width-50, :height => bounds.height-50) do
			stroke_axis(:negative_axes_length => 15, :step_length => 50)
			stroke_circle [0, 0], 10
			text "Hello MCP!"
		end
	end
	return tmpfile
end

options = {}
optparse = OptionParser.new do |opts|
	opts.on('-u', '--username USERNAME', 'cimpress open username') do |user|
		options[:user] = user
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
else
	puts "username required"
end

case options[:mode]

  #List all the products from the staging print fulfillment API.
when 'list_products'
    mcp.list_products.each { |product|
		puts "#{product['Sku']}: #{product['ProductName']}"
	}

  #Creates a .pdf document with some filler content, uploads it and creates a printable document
when 'create_doc'
	tmpfile = create_example_pdf
	upload = mcp.upload_file(file: File.new(tmpfile))
	File.delete(tmpfile)
	doc = mcp.create_document(sku: 'VIP-44525', upload: "https://uploads.documents.cimpress.io/v1/uploads/#{upload['uploadId']}")
	puts "Document ID #{doc['Input']['DocId']} created"
	puts "http://rendering.documents.cimpress.io/v1/uds/preview?width=500&instructions_uri" + URI.escape(doc['Output']['PreviewInstructionSourceUrl'], /\W/)
	#Creates a .pdf document with some filler content and attempt to rasterize it
when 'rasterize_doc'
		tmpfile = create_example_pdf
		rasterizeResponse = mcp.rasterize_doc(file: File.new(tmpfile))
		File.delete(tmpfile)
		puts rasterizeResponse['ResultUrl']
when 'get_fulfillment_recommendations'
	puts mcp.get_fulfillment_recommendations(sku: 'VIP-44525', quantity: 250, country: 'US', postal_code: '01331')
else
    puts "Unknown mode specified."
end
