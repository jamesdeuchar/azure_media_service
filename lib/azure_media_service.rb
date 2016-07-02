require 'azure_media_service/version'
require 'azure_media_service/errors'
require 'azure_media_service/config'
require 'azure_media_service/request'
require 'azure_media_service/model'

require 'base64'
require 'openssl'
require 'securerandom'
require 'faraday'
require 'faraday_middleware'
require 'time'
require 'mime/types'
require 'base64'
require 'builder/xmlmarkup'

module AzureMediaService

  class Account 

    def initialize(id, key, proxy)
      @request ||= Request.new(client_id:id, client_secret:key, proxy_url: proxy)
    end

    def assets(asset_id=nil)
      get_object('Assets', Asset, asset_id)      
    end
    def channels(channel_id=nil)
      get_object('Channels', Channel, channel_id)
    end
    def locators(locator_id=nil)
      get_object('Locators', Locator, locator_id)      
    end
    def programs(program_id=nil)
      get_object('Programs', Program, program_id)      
    end
    def streamingendpoints(se_id=nil)
      get_object('StreamingEndpoints', StreamingEndpoint, se_id)      
    end
    def operation(op_id)
      unless op_id.nil?
        return get_object('Operations', Operation, op_id)
      end
      return nil
    end

    private
    
    def get_object(obj_type, obj_klass, obj_id=nil)
      if obj_id.nil? 
        return get(obj_type, obj_klass, obj_id)
      else
        if obj_id.match(/#{Config::GUID_PREFIX[obj_type]}/)
          return get(obj_type, obj_klass, obj_id)
        else
          get(obj_type, obj_klass, nil).each do |obj|
            return obj if obj['Name'] == obj_id
          end
          puts "ERROR: #{obj_klass} '#{obj_id} not found" 
        end
      end
      return nil
    end

    def post_object(obj_klass)
      obj_klass.new(@request, res["d"])
      post(obj_type, obj_klass)
    end

    def get(method, klass, id=nil)
      results = []
      if id.nil?
        res = @request.get(method)
        if res["d"]
          res["d"]["results"].each do |a|
            results << klass.new(@request, a)
          end
        end
      else
        res = @request.get("#{method}('#{id}')")
        results = nil
        if res["d"]
          results = klass.new(@request, res["d"])
        end
      end
      results
    end

    def post(method, body)
      @request.post(method, body)
    end

  end

end
