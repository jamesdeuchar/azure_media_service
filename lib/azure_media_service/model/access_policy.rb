module AzureMediaService
  class AccessPolicy < Model::Base
    
    class << self
      def create(request, name, duration_minutes, permission)
        post_body = {
          "Name" => name,
          "DurationInMinutes" => duration_minutes,
          "Permissions" => permission
        }
        create_response(request, request.post("AccessPolicies", post_body))
      end
    end

    
    def delete
      begin
        @request.delete("AccessPolicies('#{self.Id}')")
      rescue => e
        raise MediaServiceError.new("Failed to delete access policy '#{self.Id} - #{e.message}")
      end
    end

  end
end
