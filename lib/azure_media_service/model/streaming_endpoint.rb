module AzureMediaService
  class StreamingEndpoint < Model::Base



    class << self

#      def create(name, options=0)
#        post_body = {
#          "Name" => name,
#          "Options" => options
#        }
#        create_response(service.post("Channels", post_body))
#      end

    end

    def locators
      locators = []
      _uri = URI.parse(self.Locators["__deferred"]["uri"])
      url = _uri.path.gsub('/api/','')
      res = @request.get(url)
      res["d"]["results"].each do |v|
        locators << Locator.new(v)
      end
      locators
    end

    def content_keys
      content_keys = []
      _uri = URI.parse(self.ContentKeys["__deferred"]["uri"])
      url = _uri.path.gsub('/api/','')
      res = @request.get(url)
      res["d"]["results"].each do |v|
        content_keys << ContentKey.new(v)
      end
      content_keys
    end

    def delivery_policies
      delivery_policies = []
      _uri = URI.parse(self.DeliveryPolicies["__deferred"]["uri"])
      url = _uri.path.gsub('/api/','')
      res = @request.get(url)
      res["d"]["results"].each do |v|
        delivery_policies << AssetDeliveryPolicy.new(v)
      end
      delivery_policies
    end

    def start
      begin 
        raise 'Endpoint not in stopped state - start not attempted' if self.State != 'Stopped'
        puts "INFO: Starting endpoint #{self.Name}"
        res = @request.post("StreamingEndpoints('#{CGI.escape(self.Id)}')/Start", {})
      rescue => e
        puts "ERROR: Failed to start streamingendpoint '#{self.Name}': #{e.message}"
      end
      res
    end

    def scale(units)
      begin 
        raise 'Endpoint not in running state - scale not attempted' if self.State != 'Running'
        puts "INFO: Scaling endpoint #{self.Name}"
        res = @request.post("StreamingEndpoints('#{CGI.escape(self.Id)}')/Scale", {"scaleUnits" => units})
      rescue => e
        puts "ERROR: Failed to scale streamingendpoint '#{self.Name}': #{e.message}"
      end
      res
    end


    def stop
      begin 
        raise 'Endpoint not in running state - stop not attempted' if self.State != 'Running'
        puts "INFO: Stopping endpoint #{self.Name}"
        res = @request.post("StreamingEndpoints('#{CGI.escape(self.Id)}')/Stop", {})
      rescue => e
        puts "ERROR: Failed to stop streamingendpoint '#{self.Name}': #{e.message}"
      end
      res
    end

    
    def delete
      begin 
        res = @request.delete("StreamingEndpoint('#{self.Id}')")
        clear_cache
      rescue => e
        puts "ERROR: Failed to delete streamingendpoint '#{self.Name}': #{e.message}"
      end
      res
    end

    def content_key_link(content_key)
      @request.post("StreamingEndpoint('#{CGI.escape(self.Id)}')/$links/ContentKeys", {uri: content_key.__metadata['uri']})
    end

    def delivery_policy_link(asset_delivery_policy)
      @request.post("StreamingEndpoint('#{CGI.escape(self.Id)}')/$links/DeliveryPolicies", {uri: channel_delivery_policy.__metadata['uri']})
    end


  end

end
