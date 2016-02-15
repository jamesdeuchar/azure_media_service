module AzureMediaService
  class Operation < Model::Base

    class << self

      def get(request, operation_id)
        if program_id.nil?
          return nil
        else
          res = request.get("Operations('#{CGI.escape(operation_id)}')")
          results = nil
          if res["d"]
            results = Operation.new(request, res["d"])
          end
        end
        results
      end
      
    end

  end

end
