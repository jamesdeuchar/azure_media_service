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

      class << self

        def create_response(req, res)
          if res["d"]
            self.new(req, res["d"])
          else
            raise MediaServiceError.new(res["error"]["message"]["value"])
          end
        end

      end
    end
  end
end
