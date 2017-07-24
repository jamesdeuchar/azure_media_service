module AzureMediaService
  class ContentKeyAuthorizationPolicy < Model::Base

    class << self
      def create(request, name)
        create_response(request, request.post("ContentKeyAuthorizationPolicies", {Name: name}))
      end

      def get(request, content_key_authorization_policy_id=nil)
        request.get("ContentKeyAuthorizationPolicies('#{CGI.escape(content_key_authorization_policy_id)}')" )
      end
    end

    def link_options(options)
      @request.post("ContentKeyAuthorizationPolicies('#{CGI.escape(self.Id)}')/$links/Options",
                    {uri: options.uri('ContentKeyAuthorizationPolicyOptions')},
                    {"DataServiceVersion" => "1.0;NetFx"})
    end

    def delete
      begin 
        res = @request.delete("ContentKeyAuthorizationPolicies('#{self.Id}')")
      rescue => e
        raise MediaServiceError.new("Failed to delete content key authorization policy '#{self.Id}' - #{e.message}")
      end
      res
    end
  end
end
