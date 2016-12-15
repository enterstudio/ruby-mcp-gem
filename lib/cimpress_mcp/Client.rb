module Cimpress_mcp
require 'net/http'
require 'openssl'
require 'json'
require 'rest-client'
require 'securerandom'

class Client
    def initialize(username: nil, password: nil)
        #prefer a refresh token
        if username
            @authmode = :userpw
            @username = username
            @password = password
        else
            #TODO: implement a storable token authentication method
            raise "Require authentication information"
        end
        @tokens = {}

        load_endpoint_config
    end

    #Reads the endpoint configuration file and converts it to a list of endpoint config blocks.
    def load_endpoint_config
      @config = YAML::load_file ('conf/config.yaml')

      #Get all the service-specific configuration details.
      @services = @config["services"]
    end

    def get_token(client_id:)
        #TODO cache tokens by client_id
        form_data = {
            'client_id' => client_id,
            #TODO: how to pick the right connection?
            'connection'=> 'CimpressADFS',
            'scope' => 'openid email app_metadata',
        }
        case @authmode
        when :userpw
            form_data['username'] = @username
            form_data['password'] = @password
            response = RestClient::Request.execute(
                method: :post,
                url: 'https://cimpress.auth0.com/oauth/ro',
                payload: form_data,
                #TODO: trust correct CA keys for auth0 and cimpress endpoints
                verify_ssl: OpenSSL::SSL::VERIFY_NONE,
            )
        end
        authdata = JSON.parse(response)
        return authdata['id_token']
    end

    def list_products
        response = RestClient::Request.execute(
            method: :get,
            url: @services["staging_print_fulfillment_api"]["endpoint_url"],
            headers: {'Authorization': "Bearer #{get_token(client_id: @services["staging_print_fulfillment_api"]["client_id"])}"},
            verify_ssl: OpenSSL::SSL::VERIFY_NONE,
        )
	    return JSON.parse(response)
    end

    def create_barcode()
        puts
        response = RestClient::Request.execute(
            method: :get,
            url: @services["barcode_image_creator"]["endpoint_url"],
            headers: {'Authorization': "Bearer #{get_token(client_id: @services["barcode_image_creator"]["client_id"])}",
                      params: {text: "testing", barcodeType: "code128", textColor: "black", width:"300", height: "300"},
                      'Accept': 'application/json'},

            verify_ssl: OpenSSL::SSL::VERIFY_NONE,
        )
        return JSON.parse(response)
    end
    def rasterize_doc(file:)
        response = RestClient::Request.execute(
            method: :post,
            url: @services["rasterization"]["endpoint_url"],
            headers: {'Authorization': "Bearer #{get_token(client_id: @services["rasterization"]["client_id"])}",
                      'Content-Type': "application/json",
                      'Accept': "application/json"},
            payload: { :body => file },
            verify_ssl: OpenSSL::SSL::VERIFY_NONE,
        )
        puts "Response: #{response}"
        return JSON.parse(response)
    end

    def upload_file(file:)
        response = RestClient::Request.execute(
            method: :post,
            url: 'https://uploads.documents.cimpress.io/v1/uploads',
            headers: {'Authorization': "Bearer #{get_token(client_id: 'WuPUpCSkomz4mtPxCIXbLdYhgOLf4fhJ')}"},
            payload: { :body => file },
            verify_ssl: OpenSSL::SSL::VERIFY_NONE,
        )
        #returns an array, but we only ever send one file, so return the first element
	    return JSON.parse(response)[0]
    end

    def create_document(sku:, upload:)
        docid = SecureRandom.uuid
        doc_request = <<-DOC
            {
            "McpSku": "#{sku}",
            "Pdfs": [ "#{upload}" ],
            "PositioningScheme": "auto",
            "RotationScheme": "auto"
            }
        DOC
        response = RestClient::Request.execute(
            method: :post,
            url: "https://orchestration.documents.cimpress.io/v1/fullbleed/#{docid}?async=false",
            headers: {content_type: :json, 'Authorization': "Bearer #{get_token(client_id: 'KXae6kIBE9DcSqHRyQB92PytnbdgykQL')}"},
            payload: doc_request,
            verify_ssl: OpenSSL::SSL::VERIFY_NONE,
        )
        return JSON.parse(response)
    end

    def get_fulfillment_recommendations(sku:, quantity:, country:, postal_code:)
        response = RestClient::Request.execute(
            method: :get,
            url: "https://recommendations.commerce.cimpress.io/v3/fulfillmentrecommendations/#{sku}",
            headers: {
                content_type: :json,
                'Authorization': "Bearer #{get_token(client_id: '0o9e54NwpXutAxVkylQXzhoRZN47NEGy')}",
                params: {quantity: quantity, country: country, postalCode: postal_code}
            },
            verify_ssl: OpenSSL::SSL::VERIFY_NONE,
        )
        return JSON.parse(response)
    end
end
end