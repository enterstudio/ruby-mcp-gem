module Cimpress_mcp
require 'net/http'
require 'openssl'
require 'json'
require 'rest-client'
require 'securerandom'
require 'cimpress_mcp/config'
require 'jwt'

class Client
    def initialize(username: nil, password: nil, refresh_token: nil)
        if username
            @authmode = :userpw
            @username = username
            @password = password
        elsif refresh_token
            @authmode = :refresh_token
            @refresh_token = refresh_token
        else
            #TODO: implement a storable token authentication method
            raise "Require authentication information"
        end
        @tokens = {}
    end

    def get_token(client_id:)
        #check if we have a chached token, and that it doesn't expire in the next 30 seconds
        if (@tokens[client_id] && @tokens[client_id][:exp] > Time.now.getutc.to_i+30)
            return @tokens[client_id][:token]
        end

        case @authmode
            when :userpw
                #Internal auth domains are handled differently for now.
                if @username.end_with?('cimpress.com') or
                        @username.end_with?('cimpress.net') or
                        @username.end_with?('vistaprint.com') or
                        @username.end_with?('vistaprint.net') or
                        @username.end_with?('albumprinter.com') or
                        @username.end_with?('druck.at') or
                        @username.end_with?('flprint.local') or
                        @username.end_with?('pixartprinting.com') or
                        @username.end_with?('tradeprint.co.uk') or
                        @username.end_with?('fotoknudsen.no')
                    connection = 'CimpressADFS'    
                else
                    connection = 'default'
                end
                form_data = {
                    'client_id' => client_id,
                    'connection'=> connection,
                    'scope' => 'openid email app_metadata',
                    'username' => @username,
                    'password' => @password
                }
                response = RestClient::Request.execute(
                    method: :post,
                    url: 'https://cimpress.auth0.com/oauth/ro',
                    payload: form_data,
                    #TODO: trust correct CA keys for auth0 and cimpress endpoints
                    verify_ssl: OpenSSL::SSL::VERIFY_NONE,
                )
            when :refresh_token
                form_data = {
                    'client_id' => 'QkxOvNz4fWRFT6vcq79ylcIuolFz2cwN',
                    'grant_type' => 'urn:ietf:params:oauth:grant-type:jwt-bearer',
                    'api_type' => 'auth0',
                    'scope' => 'openid name email',
                    'target' => client_id,
                    'refresh_token' => @refresh_token
                }
                response = RestClient::Request.execute(
                    method: :post,
                    url: 'https://cimpress.auth0.com/delegation',
                    payload: form_data,
                    #TODO: trust correct CA keys for auth0 and cimpress endpoints
                    verify_ssl: OpenSSL::SSL::VERIFY_NONE,
                )
        end
        authdata = JSON.parse(response)
        @tokens[client_id] = {
            :exp => JWT.decode(authdata['id_token'], nil, false)[0]['exp'],
            :token => authdata['id_token']
        }
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

    def get_product(sku:)
        response = RestClient::Request.execute(
            method: :get,
            url: SERVICES[:print_fulfillment_api][:endpoint_url] + "/v1/products/#{sku}",
            headers: {'Authorization': "Bearer #{get_token(client_id: SERVICES[:print_fulfillment_api][:client_id])}"},
            verify_ssl: OpenSSL::SSL::VERIFY_NONE,
        )
	    return JSON.parse(response)
    end

    def get_surfaces(sku:)
        response = RestClient::Request.execute(
            method: :get,
            url: SERVICES[:print_fulfillment_api][:endpoint_url] + "/v1/products/#{sku}/surfaces",
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
        req_body = {
            :McpSku => "#{sku}",
            :Pdfs => [ "#{upload}"],
            :PositioningScheme => "auto",
            :RotationScheme => "auto"
        }
        doc_request =  JSON.generate(req_body)

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

    def get_scene_render(document_reference:, width:)
        response = RestClient::Request.execute(
            method: :get,
            url: SERVICES[:print_fulfillment_api][:endpoint_url] + 'v2/documents/scenes',
            headers: {
                content_type: :json,
                'Authorization': "Bearer #{get_token(client_id: SERVICES[:print_fulfillment_api][:client_id])}",
                params: {documentReferenceUrl: document_reference, width: width}
            },
            verify_ssl: OpenSSL::SSL::VERIFY_NONE,
        )
        return JSON.parse(response)
    end

    def validate_api(swagger_url_to_validate:)
        req_body = {:swagger_url => "#{swagger_url_to_validate}"}
        validate_request =  JSON.generate(req_body)
        response = RestClient::Request.execute(
            method: :POST,
            url: SERVICES[:api_validation][:endpoint_url] + "validate/",
            headers: {
                content_type: :json,
                accept: :json,
                'Authorization': "Bearer #{get_token(client_id: SERVICES[:api_validation][:client_id])}",
            },
            payload: validate_request,
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
