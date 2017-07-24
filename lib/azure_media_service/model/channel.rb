module AzureMediaService
  class Channel < Model::Base

    class << self
      def create(request, name, options={})
        channel = { "Id" => nil,
                		"Name" => name,
                		"Description": options['Description'] || name,
                    "Created"      => "0001-01-01T00:00:00",  
                    "LastModified" => "0001-01-01T00:00:00",
                		"State" => nil,
                		"Input" => { "KeyFrameInterval"  => nil,
                            		 "StreamingProtocol" => options['StreamingProtocol'] || "FragmentedMP4",
                            		 "AccessControl" => { "IP" => {"Allow" => [{"Name" => "Allow All","Address" => "0.0.0.0","SubnetPrefixLength" => 0}]}},
                            		 "Endpoints" => [] },
                		"Preview" => { "AccessControl" => nil,
                                   "Endpoints" => [] },
                		"Output" => nil,
                		"CrossSiteAccessPolicies" => { "ClientAccessPolicy" => options['ClientAccessPolicy'],
                                                   "CrossDomainPolicy"  => options['CrossDomainPolicy'] },
                		"EncodingType" => options['EncodingType'] || "None",
                		"Encoding" => nil,
                		"Slate" => nil }
        new_channel, operation_id = request.post("Channels", channel)
        return create_response(request, new_channel), operation_id
      end
    end

    def create_program(name, description=nil, manifest_name=nil, locator_id=nil, duration=nil, key_acquisition_domain=nil)
      Program.create(@request, self.Id, name, description, manifest_name, locator_id, duration, key_acquisition_domain)
    end
      
    def programs
      self.get("Channels('#{CGI.escape(self.Id)}')/Programs", Program)
    end

    def inputs
      self.Input["Endpoints"]
    end
    
    def get_input_acls
      return nil if self.Input["AccessControl"].nil?
      self.Input["AccessControl"]["IP"]["Allow"]
    end
    
    def set_input_acls(acls)
      input_update = self.Input.dup
      if acls.nil?
        input_update['AccessControl'] = { "IP" => nil}
      elsif acls.kind_of?(Array)
        validate_acls(acls)
        input_update['AccessControl'] = { "IP" => { "Allow" => acls }}
      else
        raise 'Expected array of ACLs or nil!'
      end
      @request.patch("Channels('#{CGI.escape(self.Id)}')", { "Input" => input_update })
    end
        
    def get_preview_acls
      return nil if self.Preview["AccessControl"].nil?
      self.Preview["AccessControl"]["IP"]["Allow"]
    end
    
    def set_preview_acls(acls)
      preview_update = self.Preview.dup
      if acls.nil?
        preview_update['AccessControl'] = { "IP" => nil}
      elsif acls.kind_of?(Array)
        validate_acls(acls)
        preview_update['AccessControl'] = { "IP" => { "Allow" => acls }}
      else
        raise 'Expected array of ACLs or nil!'
      end
      @request.patch("Channels('#{CGI.escape(self.Id)}')", { "Preview" => preview_update })
    end
    
    def start
      @request.post("Channels('#{CGI.escape(self.Id)}')/Start", {})
    end

    def stop
      @request.post("Channels('#{CGI.escape(self.Id)}')/Stop", {})
    end

    def reset
      @request.post("Channels('#{CGI.escape(self.Id)}')/Reset", {})
    end
    
    def delete
      @request.delete("Channels('#{CGI.escape(self.Id)}')")
    end
    
    private
      def validate_acls(acls)
        acls.each do |acl|
          raise "ACL #{acl} is missing a required key!" if ! %w(Name Address SubnetPrefixLength).all? {|s| acl.key? s}
          raise "ACL #{acl} has an invalid IP address format" if ! acl["Address"].match(/\b\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\b/)
          raise "ACL #{acl} has an invalid integer value" if ! acl["SubnetPrefixLength"].kind_of?(Integer) ||
                                                              (acl["SubnetPrefixLength"] < 0 || acl["SubnetPrefixLength"] > 32)
        end
      end
  end

end
