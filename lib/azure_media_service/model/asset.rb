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
        asset = create_response(request, request.post("Assets", post_body))
        return asset
      end

    end

    def delete
      policy_ids = Array.new
      self.locators.each do |locator|
        begin
          policy_ids << locator['AccessPolicyId']
          locator.delete
        rescue => e
          raise MediaServiceError.new("Failed to delete locator for asset '#{self.Id}' - #{e.message}")
        end
      end

      policy_ids.each do |policy_id|
        begin
          res = @request.delete("AccessPolicies('#{policy_id}')")
        rescue => e
          raise MediaServiceError.new("Failed to delete access policy for asset '#{self.Id}' - #{e.message}")
        end
      end

      begin
        res = @request.delete("Assets('#{self.Id}')")
      rescue => e
        raise MediaServiceError.new("Failed to delete asset '#{self.Id}' - #{e.message}")
      end
      res
    end

    def locators
      self.get("Assets('#{CGI.escape(self.Id)}')/Locators", Locator)
    end

    def files
      self.get("Assets('#{CGI.escape(self.Id)}')/Files", AssetFile)
    end

    def content_keys
      self.get("Assets('#{CGI.escape(self.Id)}')/ContentKeys", ContentKey)
    end

    def delivery_policies
      self.get("Assets('#{CGI.escape(self.Id)}')/DeliveryPolicies", AssetDeliveryPolicy)
    end

    def link_content_key(content_key)
      @request.post("Assets('#{CGI.escape(self.Id)}')/$links/ContentKeys", {uri: content_key.uri('ContentKeys')}, {"DataServiceVersion" => "1.0;NetFx"})
    end
    
    def link_delivery_policy(asset_delivery_policy)
      @request.post("Assets('#{CGI.escape(self.Id)}')/$links/DeliveryPolicies", {uri: asset_delivery_policy.uri('AssetDeliveryPolicies')}, {"DataServiceVersion" => "1.0;NetFx"})
    end

  end

end
