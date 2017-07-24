module AzureMediaService
  class Program < Model::Base
    
    class << self

      def create(request, channel_id, name, description='null', manifest_name='null', locator_id=nil, duration=nil, key_acquisition_domain=nil)
        duration = duration || 'PT12H'
        raise "Duration '#{duration}' is in expected ISO format" unless duration.match(/^PT\d+/)
        if locator_id
          if m = locator_id.match(/^nb:lid:UUID:(.*)$/)
            locator_uuid = m[1]
          else
            locator_uuid = locator_id
            locator_id   = "nb:lid:UUID:#{locator_uuid}"
          end
          if locator_uuid !~ /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/
            raise "Locator uuid '#{locator_uuid}' is not a valid lower-case locator uuid"
          end
        else
          locator_uuid = SecureRandom.uuid
          locator_id   = "nb:lid:UUID:#{locator_uuid}"
        end
        asset = policy = locator = content_key = delivery_policy = nil
        begin
          asset   = Asset.create(request, name)
          post_body = {
            "ChannelId"           => channel_id,
            "AssetId"             => asset['Id'],
            "Name"                => name,
            "Description"         => description,
            "ManifestName"        => manifest_name,
            "ArchiveWindowLength" => duration,
            "Created"             => "0001-01-01T00:00:00",
            "LastModified"        => "0001-01-01T00:00:00",
            "State"               => 'Creating'
          }
          program = self.create_response(request, request.post('Programs', post_body))
          if key_acquisition_domain
            key_acquisition_url = "https://#{key_acquisition_domain}/#{locator_uuid}/#{program['ManifestName']}.ism/"
            content_key = ContentKey.create_open_aes(request)
            asset.link_content_key(content_key)
            delivery_policy = AssetDeliveryPolicy.create_hls_aes_only(request, key_acquisition_url)
            asset.link_delivery_policy(delivery_policy)
          end
          policy  = AccessPolicy.create(request, 'Policy', 5256000, 1)
          locator = Locator.create(request, policy['Id'], asset['Id'], 2, locator_id)
        rescue => e
          locator.delete if locator
          policy.delete  if policy
          program.delete if program
          asset.delete   if asset
          content_key.delete if content_key
          delivery_policy.delete if delivery_policy
          raise e
        end
        return program
      end

    end

    def reset
      channel_id     = self['ChannelId'] 
      name           = self['Name']
      description    = self['Description']
      manifest_name  = self['ManifestName']
      archive_window = self['ArchiveWindowLength']
      locator_id     = nil
      self.locators.each do |locator|
        locator_id = locator['Id']
      end
      asset = Asset.get(@request, self['AssetId'])
      delivery_policies = asset.delivery_policies
      if delivery_policies.any?
        key_acquisition_domain = URI.parse(JSON.parse(delivery_policies.first['AssetDeliveryConfiguration'])[0]['Value']).host
      else
        key_acquisition_domain = nil
      end
      self.delete
      asset.delete
      program = Program.create(@request, channel_id, name, description, manifest_name, locator_id, archive_window, key_acquisition_domain)
    end

    def files
      self.get("Assets('#{CGI.escape(self.AssetId)}')/Files", AssetFile)      
    end
    
    def locators
      self.get("Assets('#{CGI.escape(self.AssetId)}')/Locators", Locator)      
    end

    def delivery_policies
      self.get("Assets('#{CGI.escape(self.AssetId)}')/DeliveryPolicies", AssetDeliveryPolicy)      
    end
    
    def start
      @request.post("Programs('#{CGI.escape(self.Id)}')/Start", {})
    end

    def stop
      @request.post("Programs('#{CGI.escape(self.Id)}')/Stop", {})
    end

    def delete
      @request.delete("Programs('#{self.Id}')")
    end

  end

end
