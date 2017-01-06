module Cimpress_mcp
require 'optparse'
require 'io/console'
require 'prawn'
require "prawn/measurement_extensions"
require 'tmpdir'
require 'uri'
require 'yaml'
require 'cimpress_mcp'

class Cli
	#Creates an example pdf document and fills it with random content.
	def create_example_pdf(size: "A6", text: "Hello MCP!")
		tmpfile = Dir::Tmpname.make_tmpname(['MCPDOC', '.pdf'], nil)
		Prawn::Document.generate(tmpfile, :page_size => size,:page_layout => :landscape, :margin => 0) do
			stroke_circle [0, 0], 10
			bounding_box([25, bounds.height-25], :width => bounds.width-50, :height => bounds.height-50) do
				stroke_axis(:negative_axes_length => 15, :step_length => 50)
				stroke_circle [0, 0], 10
				text text
			end
		end
		return tmpfile
	end

	def main(argv)
		options = {}
		optparse = OptionParser.new do |opts|
			opts.on('-u', '--username USERNAME', 'cimpress open username') do |user|
				options[:user] = user
			end
			opts.on('-m', '--mode MODE', 'command mode - operation to run') do |mode|
				options[:mode] = mode
			end
			opts.on('-s', '--sku SKU', 'MCP product SKU') do |sku|
				options[:sku] = sku
			end
			opts.on('-t', '--text TEXT', 'Text to decorate product') do |text|
				options[:text] = text
			end

		end
		optparse.parse!

		if options[:user]
			print "Password: "
			password = STDIN.noecho(&:gets).chomp
			puts
			mcp = Cimpress_mcp::Client.new(username: options[:user], password: password )
		else
			puts "username required"
		end

		case options[:mode]

			#List all the products from the staging print fulfillment API.
			when 'list_products'
				mcp.list_products.each { |product|
					puts "#{product['Sku']}: #{product['ProductName']}"
				}
			
			when 'get_product'
				print "SKU: "
				sku = gets.chomp
				product = mcp.get_product(sku: sku)

				puts "#{product}"

		#Creates a .pdf document with some filler content, uploads it and creates a printable document
		when 'create_doc'
			tmpfile = create_example_pdf
			upload = mcp.upload_file(file: File.new(tmpfile))
			File.delete(tmpfile)
			doc = mcp.create_document(sku: 'VIP-44525', upload: "https://uploads.documents.cimpress.io/v1/uploads/#{upload['uploadId']}")
			puts "Document ID #{doc['Input']['DocId']} created"
			puts "http://rendering.documents.cimpress.io/v1/uds/preview?width=500&instructions_uri=" + URI.escape(doc['Output']['PreviewInstructionSourceUrl'], /\W/)

			#Creates a .pdf document with some filler content, uploads it and creates a printable document
			when 'create_doc'
				tmpfile = create_example_pdf
				upload = mcp.upload_file(file: File.new(tmpfile))
				File.delete(tmpfile)
				puts rasterizeResponse['ResultUrl']
		when 'get_fulfillment_recommendations'
			puts mcp.get_fulfillment_recommendations(sku: 'VIP-44525', quantity: 250, country: 'US', postal_code: '01331')
		when 'create_barcode'
			createBarcodeResponse = mcp.create_barcode()
			puts createBarcodeResponse
			when 'health_check'
				puts mcp.health_checks()
		when 'test_product'
			#make sure we can get the surface spec for the provided SKU
			surfaces = mcp.get_surfaces(sku: options[:sku])['Surfaces']
			#make a test document the right size for the surface using the provided text
			tmpfile = create_example_pdf(text: options[:text], size: [surfaces[0]['WidthInMm'].mm, surfaces[0]['HeightInMm'].mm])
			upload = mcp.upload_file(file: File.new(tmpfile))
			File.delete(tmpfile)
			doc = mcp.create_document(sku: options[:sku], upload: "https://uploads.documents.cimpress.io/v1/uploads/#{upload['uploadId']}")
			puts "http://rendering.documents.cimpress.io/v1/uds/preview?width=500&instructions_uri=" + URI.escape(doc['Output']['PreviewInstructionSourceUrl'], /\W/)
		else
				puts "Unknown mode specified."
		end

	end
end
