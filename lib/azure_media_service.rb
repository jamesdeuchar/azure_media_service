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

    def initialize(tenant, region, account, id, key, proxy=nil)
      @request ||= Request.new(tenant_domain: tenant,
                               region: region,
                               account_name: account, 
                               client_id:id, 
                               client_secret:key, 
                               proxy_url: proxy)
    end

    def assets(asset_id=nil)
      Asset.get(@request, asset_id)
    end
    def create_channel(name, options={})
      Channel.create(@request, name, options)
    end
    def channels(channel_id=nil)
      Channel.get(@request, channel_id)
    end
    def locators(locator_id=nil)
      Locator.get(@request, locator_id)
    end
    def programs(program_id=nil)
      Program.get(@request, program_id)
    end
    def create_streamingendpoint(name, options)
      StreamingEndpoint.create(@request, name, options)
    end
    def streamingendpoints(se_id=nil)
      StreamingEndpoint.get(@request, se_id)
    end
    def contentkey(ck_id=nil)
      ContentKey.get(@request, ck_id)
    end
    def operation(op_id)
      return nil if op_id.nil?
      Operation.get(@request, op_id)
    end

  end

end
