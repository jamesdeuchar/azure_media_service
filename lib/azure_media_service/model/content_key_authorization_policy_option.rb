module AzureMediaService
  class ContentKeyAuthorizationPolicyOption < Model::Base
    
    KeyDeliveryTypes = {
      None:             0,
      PlayReadyLicense: 1,
      BaselineHttp:     2
    }

    KeyRestrictionTypes = {
      Open:            0,
      TokenRestricted: 1,
      IPRestricted:    2
    }

    class << self
      def create(request ,name, key_delivery_type, key_delivery_configuration, restrictions)
        post_body = {
          "Name" => name,
          "KeyDeliveryType" => key_delivery_type,
          "Restrictions" => restrictions
        }
        if key_delivery_configuration
          post_body["KeyDeliveryConfiguration"] = key_delivery_configuration
        end
        create_response(request, request.post("ContentKeyAuthorizationPolicyOptions", post_body))
      end
      def get(request, content_key_authorization_policy_option_id=nil)
        request.get("ContentKeyAuthorizationPolicyOptions('#{CGI.escape(content_key_authorization_policy_option_id)}')" )
      end
    end

    def delete
      begin 
        res = @request.delete("ContentKeyAuthorizationPolicyOptions('#{self.Id}')")
      rescue => e
        raise MediaServiceError.new("Failed to delete content key authorization policy option '#{self.Id}' - #{e.message}")
      end
      res
    end
  end
end

