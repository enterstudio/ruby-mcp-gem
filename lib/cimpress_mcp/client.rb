module Cimpress_mcp
require 'net/http'
require 'openssl'
require 'json'
require 'rest-client'
require 'securerandom'
require 'cimpress_mcp/config'
require 'erb'

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
            url: SERVICES[:print_fulfillment_api][:endpoint_url] + "v1/partner/products",
            headers: {'Authorization': "Bearer #{get_token(client_id: SERVICES[:print_fulfillment_api][:client_id])}"},
            verify_ssl: OpenSSL::SSL::VERIFY_NONE,
        )
	    return JSON.parse(response)
    end

    def create_barcode()
        puts
        response = RestClient::Request.execute(
            method: :get,
            url: SERVICES[:barcode_image_creator][:endpoint_url],
            headers: {'Authorization': "Bearer #{get_token(client_id: SERVICES[:barcode_image_creator][:client_id])}",
                      params: {text: "testing", barcodeType: "code128", textColor: "black", width:"300", height: "300"},
                      'Accept': 'application/json'},

            verify_ssl: OpenSSL::SSL::VERIFY_NONE,
        )
        return JSON.parse(response)
    end
    def rasterize_doc(file:)
        response = RestClient::Request.execute(
            method: :post,
            url: SERVICES[:rasterization][:endpoint_url],
            headers: {'Authorization': "Bearer #{get_token(client_id: SERVICES[:rasterization][:client_id])}",
                      'Content-Type': "application/json",
                      'Accept': "application/json"},
            payload: { :body => file },
            verify_ssl: OpenSSL::SSL::VERIFY_NONE,
        )
        puts "Response: #{response}"
        return JSON.parse(response)
    end
    def clean_image(image_url:)
        RestClient.log= 'stdout'
        response = RestClient::Request.execute(
            method: :post,
            url: SERVICES[:doc_review_clean_image][:endpoint_url],
            headers: {
                'Authorization': "Bearer #{get_token(client_id: SERVICES[:doc_review_clean_image][:client_id])}",
                'params': {fileUrl: "#{image_url}"},
                'Content-Type': "application/json",
                'Accept': "application/json"
            },
            payload: "{colorInfoList : [ColorInfo: {ThreadID : 'unique_string'}]",
            verify_ssl: OpenSSL::SSL::VERIFY_NONE,
        )
        return JSON.parse(response)
    end
    def crispify_image(image_url:)

        image_url = ERB::Util.url_encode(image_url)
        puts "Image URL: #{image_url}"

        RestClient.log= 'stdout'
        response = RestClient::Request.execute(
            method: :post,
            url: SERVICES[:crispify][:endpoint_url],
            headers: {
                'Authorization': "Bearer #{get_token(client_id: SERVICES[:crispify][:client_id])}",
                'params': {asynchronous: "false"},
                'Content-Type': "application/json",
                'Accept': "application/json"
            },
            payload: "{ImageUrl : #{image_url}}",
            verify_ssl: OpenSSL::SSL::VERIFY_NONE,
        )
        return JSON.parse(response)
    end
    def upload_file(file:)

        response = RestClient::Request.execute(
            method: :post,
            url: SERVICES[:uploads][:endpoint_url],
            headers: {'Authorization': "Bearer #{get_token(client_id: SERVICES[:uploads][:client_id])}"},
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
            url: SERVICES[:document_orchestration][:endpoint_url] + "fullbleed/#{docid}?async=false",
            headers: {content_type: :json, 'Authorization': "Bearer #{get_token(client_id: SERVICES[:document_orchestration][:client_id])}"},
            payload: doc_request,
            verify_ssl: OpenSSL::SSL::VERIFY_NONE,
        )
        return JSON.parse(response)
    end

    def get_fulfillment_recommendations(sku:, quantity:, country:, postal_code:)
        response = RestClient::Request.execute(
            method: :get,
            url: SERVICES[:fulfillment_recommendations][:endpoint_url] + "fulfillmentrecommendations/#{sku}",
            headers: {
                content_type: :json,
                'Authorization': "Bearer #{get_token(client_id: SERVICES[:fulfillment_recommendations][:client_id])}",
                params: {quantity: quantity, country: country, postalCode: postal_code}
            },
            verify_ssl: OpenSSL::SSL::VERIFY_NONE,
        )
        return JSON.parse(response)
    end

    #Runs the health check command against all known services and returns
    #a hash of key:'service name' value:boolean representing the check status.
    def health_checks
        SERVICES.each do |service_name, service_info|
            puts "Health Checking this service URL:  #{service_info[:health_check_url]}"
                response = RestClient::Request.execute(
                    method: :get,
                    url: service_info[:health_check_url]
                )
            puts JSON.parse(response)
        end
    end

end
end
