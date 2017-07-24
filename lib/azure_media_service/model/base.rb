require 'ostruct'
#require "base"

module AzureMediaService
  module Model
    class Base < OpenStruct

      attr_reader :original_data

      def initialize(request, hash)
        @request = request
        super(hash)
      end

      def get(method, klass=nil)
        results = []
        klass = self if klass.nil?
        res = @request.get(method)
        if res["Id"]
          results = klass.new(@request, res)
        elsif res["value"]
          res["value"].each do |obj|
            results << klass.new(@request, obj)
          end
        end  
        results
      end
      
      def uri(method)
        begin
          uri = URI.parse(self["odata.metadata"])
          if m = uri.path.match(/^\/(.*)\/\$metadata/)
            return "#{uri.scheme}://#{uri.host}/#{m[1]}/#{method}('#{CGI.escape(self.Id)}')"
          end
          raise MediaServiceError.new("Failed to get content key uri - path didn't match")
        rescue => e
          raise MediaServiceError.new("Exception getting content key uri - #{e.message}")
        end
      end
      
      class << self

        def create_response(req, res)
          if res.has_key?('Id')
            self.new(req, res)
          else
            raise MediaServiceError.new(res["error"]["message"]["value"])
          end
        end

        def get(req, id=nil)
          results = []
          klass_name = self.name.split('::').last
#TODO fix me          
          method = "#{klass_name}s"
          if id
            id = "#{Config::GUID_PREFIX[klass_name.split('::').last]}:#{id}"  if ! id.match(/^nb:/)
            method = "#{method}('#{id}')"
          end
          res = req.get(method)
          if id
            results = self.new(req, res)
          else
            res["value"].each do |obj|
              results << self.new(req, obj)
            end
          end
          return results
        end
        
      end
    end
  end
end
