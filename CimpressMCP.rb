module CimpressMCP
require 'net/http'
require 'openssl'
require 'json'

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
            raise "Require either a refresh token or a username and password"
        end
        @tokens = {}
    end

    def get_token(client_id:)
        #TODO cache tokens by client_id
        uri = URI('https://cimpress.auth0.com/oauth/ro')
        req = Net::HTTP::Post.new(uri)
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
        req.set_form_data(form_data)

	    http = Net::HTTP.new(uri.hostname, uri.port)
	    http.use_ssl = true
	    http.verify_mode = OpenSSL::SSL::VERIFY_NONE
	    #http.set_debug_output($stderr)
	    response = http.request(req)
	    authdata = JSON.parse(response.body)
	    return authdata['id_token']
    end

    def list_products
        uri = URI('https://api.cimpress.io/vcs/printapi/v1/partner/products')
	    http = Net::HTTP.new(uri.hostname, uri.port)
	    http.use_ssl = true
	    http.verify_mode = OpenSSL::SSL::VERIFY_NONE
	    req = Net::HTTP::Get.new(uri)
        token = get_token(client_id: '4GtkxJhz0U1bdggHMdaySAy05IV4MEDV')
	    req['Authorization'] = "Bearer #{token}"
	    res = http.request(req)
	    return JSON.parse(res.body)
    end
end

end