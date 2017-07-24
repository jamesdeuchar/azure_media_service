module AzureMediaService
  class StreamingEndpoint < Model::Base
    
    class << self

      def create(request, name, options={})
        streaming_endpoint = { "Id" => nil,  
                               "Name" => name,  
                               "Description" => options['Description'] || name,  
                               "Created" => "0001-01-01T00:00:00",  
                               "LastModified" => "0001-01-01T00:00:00",  
                               "State"=> nil,  
                               "HostName" => nil,  
                               "ScaleUnits" => 0,  
                               "CustomHostNames" => [],  
                               "AccessControl" => nil,  
                               "CacheControl" => nil,  
                               "CrossSiteAccessPolicies" => { "ClientAccessPolicy" => nil,  "CrossDomainPolicy" => nil },
                               "CdnEnabled" => false,
                               "CdnProfile" => nil,
                               "CdnProvider" => nil,
                               "StreamingEndpointVersion" => "1.0" }  
        new_streamingendpoint, operation_id = request.post("StreamingEndpoints", streaming_endpoint)
        return create_response(request, new_streamingendpoint), operation_id
      end
    end

    def get_output_acls
      return nil if self.AccessControl.nil?
      self.AccessControl["IP"]["Allow"]
    end
    
    def set_output_acls(acls)
      akamai_g2o = self.AccessControl ? self.AccessControl['Akamai'] : nil
      if acls.nil?
        acl = { "AccessControl" => { "IP" => nil, "Akamai" => akamai_g2o }}
      elsif acls.kind_of?(Array) 
        acls.each do |acl|
          raise "ACL #{acl} is missing a required key!" if ! %w(Name Address SubnetPrefixLength).all? {|s| acl.key? s}
          raise "ACL #{acl} has an invalid IP address format" if ! acl["Address"].match(/\b\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\b/)
          raise "ACL #{acl} has an invalid integer value" if ! acl["SubnetPrefixLength"].kind_of?(Integer) || 
                                                              (acl["SubnetPrefixLength"] < 0 || acl["SubnetPrefixLength"] > 32)
        end
        acl = { "AccessControl" => { "IP" => { "Allow" => acls }, "Akamai" => akamai_g2o }}
      else
        raise 'Expected array of ACLs or nil!'
      end
      @request.patch("StreamingEndpoints('#{CGI.escape(self.Id)}')", acl)
    end
    
    def start
      raise 'Endpoint not in stopped state - start not attempted' if self.State != 'Stopped'
      @request.post("StreamingEndpoints('#{CGI.escape(self.Id)}')/Start", {})
    end

    def scale(units)
      raise 'Endpoint not in running state - scale not attempted' if self.State != 'Running'
      @request.post("StreamingEndpoints('#{CGI.escape(self.Id)}')/Scale", {"scaleUnits" => units})
    end

    def stop
      raise 'Endpoint not in running state - stop not attempted' if self.State != 'Running'
      @request.post("StreamingEndpoints('#{CGI.escape(self.Id)}')/Stop", {})
    end

    def delete
      @request.delete("StreamingEndpoints('#{self.Id}')")
    end
    
  end

end
