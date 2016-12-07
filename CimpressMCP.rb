module CimpressMCP
require 'net/http'
require 'openssl'
require 'json'
require 'rest-client'
require 'securerandom'

class Client
    def initialize(refresh_token: nil, username: nil, password: nil)
        #prefer a refresh token
        if refresh_token
            @authmode = :token
            @token = token
        elsif username
            @authmode = :userpw
            @username = username
            @password = password
        else
            #TODO: look in ~/.cimpress/credentials for a refresh token
            raise "Require either a refresh token or a username and password"
        end
        @tokens = {}
    end

    def get_token(client_id:)
        #TODO cache tokens by client_id
        form_data = {
            'client_id' => client_id,
            #TODO: how to pick the right connection?
            'connection' => 'CimpressADFS',
            'scope' => 'openid email app_metadata'
        }
        case @authmode
        when :token
            raise "not implemented"
        when :userpw
            form_data['username'] = @username
            form_data['password'] = @password
        end

        response = RestClient::Request.execute(
            method: :post,
            url: 'https://cimpress.auth0.com/oauth/ro',
            payload: form_data,
            #TODO: trust correct CA keys for auth0 and cimpress endpoints
            verify_ssl: OpenSSL::SSL::VERIFY_NONE,
        )
        authdata = JSON.parse(response)
        return authdata['id_token']
    end

    def list_products
        response = RestClient::Request.execute(
            method: :get,
            url: 'https://api.cimpress.io/vcs/printapi/v1/partner/products',
            headers: {'Authorization': "Bearer #{get_token(client_id: '4GtkxJhz0U1bdggHMdaySAy05IV4MEDV')}"},
            verify_ssl: OpenSSL::SSL::VERIFY_NONE,
        )
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
end

end