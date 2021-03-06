module AzureMediaService
  class Request

    def initialize(config)
      build_config(config) 
    end

    def get(endpoint, params={}, custom_headers={})
      setToken() if token_expire?
      res = conn(@config[:mediaURI]).get do |req|
        req.url URI.escape(endpoint, '():')
        req.headers = default_headers(custom_headers)
        req.headers[:Authorization] = "Bearer #{@access_token}"
        req.params = params
      end
      if res.status == 200
        res.body
      elsif res.status == 301
        @config[:mediaURI] = res.headers['location']
        get(endpoint, params)
      elsif res.status == 401
        raise MediaServiceError.new("Authorisation failed")
      else
        media_service_error_response(res)
      end
    end

    def post(endpoint, body, custom_headers={})
      setToken if token_expire?
      res = conn(@config[:mediaURI]).post do |req|
        req.url endpoint
        req.headers = default_headers(custom_headers)
        req.headers[:Authorization] = "Bearer #{@access_token}"
        req.body = body
      end
      if res.status == 202 
        return res.body, res.headers['operation-id']
      elsif res.status == 201 || res.status == 204 
        return res.body
      elsif res.status == 301
        @config[:mediaURI] = res.headers['location']
        post(endpoint, body)
      elsif res.status == 401
        raise MediaServiceError.new("Authorisation failed")
      else
        media_service_error_response(res)
      end
    end

    def put(endpoint, body, custom_headers={})
      setToken if token_expire?
      res = conn(@config[:mediaURI]).put do |req|
        req.url endpoint
        req.headers = default_headers(custom_headers)
        req.headers[:Authorization] = "Bearer #{@access_token}"
        req.body = body
      end
      if res.status == 202 
        return res.body, res.headers['operation-id']
      elsif res.status == 201 || res.status == 204 
        return res.body
      elsif res.status == 301
        @config[:mediaURI] = res.headers['location']
        put(endpoint, body)
      elsif res.status == 401
        raise MediaServiceError.new("Authorisation failed")
      else
        media_service_error_response(res)
      end
    end

    def put_row(url, body)
      _conn = conn(url) do |builder|
        builder.request :multipart
      end
      headers = {}
      if block_given?
        yield(headers)
      end
      res = _conn.put do |req|
        req.headers = headers
        req.body = body
      end
      if res.status == 301
        @config[:mediaURI] = res.headers['location']
        put(url, body)
      else
        if res.headers[:error]
          raise MediaServiceError.new("#{res.headers[:error]}: #{res.headers[:error_description]}")
        end
        res.body
      end
    end

    def patch(endpoint, body, custom_headers={})
      setToken if token_expire?
      res = conn(@config[:mediaURI]).patch do |req|
        req.url endpoint
        req.headers = default_headers(custom_headers)
        req.headers[:Authorization] = "Bearer #{@access_token}"
        req.body = body
      end
      if res.status == 202 
        return res.body, res.headers['operation-id']
      elsif res.status == 201 || res.status == 204 
        return res.body
      elsif res.status == 301
        @config[:mediaURI] = res.headers['location']
        put(endpoint, body)
      elsif res.status == 401
        raise MediaServiceError.new("Authorisation failed")
      else
        media_service_error_response(res)
      end
    end
    
    def delete(endpoint, params={}, custom_headers={})
      setToken() if token_expire?
      res = conn(@config[:mediaURI]).delete do |req|
        req.url URI.escape(endpoint, '():')
        req.headers = default_headers(custom_headers)
        req.headers[:Authorization] = "Bearer #{@access_token}"
        req.params = params
      end
      if res.status == 202 
        return res.body, res.headers['operation-id']
      elsif res.status == 204 
        return res.body
      elsif res.status == 301
        @config[:mediaURI] = res.headers['location']
        delete(endpoint, params)
      elsif res.status == 401
        raise MediaServiceError.new("Authorisation failed")
      else
        media_service_error_response(res)
      end
    end

    private
      def build_config(config)
        @config = config || {}
        @config[:tenant_domain] ||= ''
        @config[:region] ||= ''
        @config[:account] ||= ''
        @config[:client_id] ||= ''
        @config[:client_secret] ||= ''
        @config[:mediaURI] = Config::MEDIA_URI % {account: @config[:account_name], region: @config[:region]}
        @config[:tokenURI] = Config::TOKEN_URI % {tenant: @config[:tenant_domain]}
        @config[:proxy_url] ||= ''
        #;odata=verbose
        @default_headers = {
          "Content-Type"          => "application/json",
          "Accept"                => "application/json",
          "DataServiceVersion"    => "3.0",
          "MaxDataServiceVersion" => "3.0",
          "x-ms-version"          => "2.15"
        }
      end
      def default_headers(custom_headers={})
        headers = @default_headers.clone
        headers.merge(custom_headers)
      end
      def conn(url)
        conn = Faraday::Connection.new(:url => url, proxy: @config[:proxy_url], :ssl => {:verify => false} ) do |builder|
          builder.request :url_encoded
          builder.use FaradayMiddleware::EncodeJson
          builder.use FaradayMiddleware::ParseJson, :content_type => /\bjson$/
          builder.adapter Faraday.default_adapter
          if block_given?
            yield(builder)
          end
        end
      end
      def conn_mp(url)
        conn = Faraday::Connection.new(:url => url, proxy: @config[:proxy_url], :ssl => {:verify => false} ) do |builder|
          builder.request :multipart
          builder.headers['content-type'] = 'multipart/form-data'
          builder.use FaradayMiddleware::ParseJson, :content_type => /\bjson$/
          builder.adapter Faraday.default_adapter
          if block_given?
            yield(builder)
          end
        end
      end
      def setToken
        res = conn_mp(@config[:tokenURI]).post do |req|
          req.body = {
            grant_type:    'client_credentials',
            client_id:     @config[:client_id],
            client_secret: @config[:client_secret],
            resource:      'https://rest.media.azure.net'
          }
        end
        @access_token = res.body["access_token"]
        @token_expires = Time.now.to_i + res.body["expires_in"].to_i
      end
      def token_expire?
        return true unless @access_token 
        return true if Time.now.to_i >= @token_expires
        return false
      end
      def media_service_error_response(response)
        raise MediaServiceError.new("#{response.body['odata.error']['code']}: #{response.body['odata.error']['message']['value']}")
      end
  end
end
