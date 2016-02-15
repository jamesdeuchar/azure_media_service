module AzureMediaService
  class Asset < Model::Base

    Options = {
      None:                       0,
      StorageEncrypted:           1,
      CommonEncryptionProtected:  2,
      EnvelopEncryptionProtected: 4
    }

    class << self

      def create(request, name)
        post_body = { "Name" => name }
        create_response(request, request.post("Assets", post_body))
      end

      def get(request, asset_id=nil)
        if asset_id.nil?
          res = request.get('Assets')
          results = []
          if res["d"]
            res["d"]["results"].each do |a|
              results << Asset.new(request, a)
            end
          end
        else
          res = request.get("Assets('#{asset_id}')")
          results = nil
          if res["d"]
            results = Asset.new(request, res["d"])
          end
        end
        results
      end

    end

    def delete
      policy_ids = Array.new
      self.locators.each do |locator|
        begin 
          policy_ids << locator['AccessPolicyId']
          locator.delete
        rescue => e
          puts "ERROR: Failed to delete locator '#{locator['Id']}': #{e.message}"
        end
      end

      policy_ids.each do |policy_id|
        begin
          res = @request.delete("AccessPolicies('#{policy_id}')")
        rescue => e
          puts "ERROR: Failed to delete access policies '#{policy_id}': #{e.message}"
        end
      end

      begin 
        res = @request.delete("Assets('#{self.Id}')")
      rescue => e
        puts "ERROR: Failed to delete asset '#{self.Id}': #{e.message}"
      end
      res
    end
    
    def locators
      locators = []
      url = "Assets('#{CGI.escape(self.Id)}')/Locators"
      res = @request.get(url)
      res["d"]["results"].each do |v|
        locators << Locator.new(@request, v)
      end
      locators
    end
    
    def files
      files = []
      if files.empty?
        _uri = URI.parse(self.Files["__deferred"]["uri"])
        url = _uri.path.gsub('/api/','')
        res = @request.get(url)
        res["d"]["results"].each do |v|
          files << AssetFile.new(@request, v)
        end
      end
      files
    end

    def content_keys
      @content_keys ||= []
      if @content_keys.empty?
        _uri = URI.parse(self.ContentKeys["__deferred"]["uri"])
        url = _uri.path.gsub('/api/','')
        res = @request.get(url)
        res["d"]["results"].each do |v|
          @content_keys << ContentKey.new(v)
        end
      end
      @content_keys
    end

    def delivery_policies
      @delivery_policies ||= []
      if @delivery_policies.empty?
        _uri = URI.parse(self.DeliveryPolicies["__deferred"]["uri"])
        url = _uri.path.gsub('/api/','')
        res = @request.get(url)
        res["d"]["results"].each do |v|
          @delivery_policies << AssetDeliveryPolicy.new(@request, v)
        end
      end
      @delivery_policies
    end

    def content_key_link(content_key)
      @request.post("Assets('#{CGI.escape(self.Id)}')/$links/ContentKeys", {uri: content_key.__metadata['uri']})
    end

    def delivery_policy_link(asset_delivery_policy)
      @request.post("Assets('#{CGI.escape(self.Id)}')/$links/DeliveryPolicies", {uri: asset_delivery_policy.__metadata['uri']})
    end


  end

end
