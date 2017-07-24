module AzureMediaService
  class Locator < Model::Base
    
    class << self
      def create(request, policy_id, asset_id, type, id=nil)
        post_body = {
          "AccessPolicyId"     => policy_id,
          "AssetId"            => asset_id,
          "Type"               => type,
          "StartTime"          => (Time.now - 5*60).gmtime.strftime('%Y-%m-%dT%H:%M:%SZ')
        }
        post_body['Id'] = id unless id.nil?
        create_response(request, request.post("Locators", post_body))
      end
    end

    def delete
      begin 
        res = @request.delete("Locators('#{self.Id}')")
      rescue => e
        raise MediaServiceError.new("Failed to delete locator '#{self.Id}' - #{e.message}")
      end
      res
    end

  end
end
