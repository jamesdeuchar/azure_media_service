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
        end
        asset = policy = locator = content_key = delivery_policy = nil
        begin
          policy  = AccessPolicy.create(request, 'Policy', 5256000, 1)
          asset   = Asset.create(request, name)
          locator = Locator.create(request, policy['Id'], asset['Id'], 2, locator_id)
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
            key_acquisition_url = "https://#{key_acquisition_domain}/#{locator['ContentAccessComponent']}/#{program['ManifestName']}.ism/"
            content_key     = ContentKey.create_open_aes(request)
            asset.content_key_link(content_key)
            delivery_policy = AssetDeliveryPolicy.create_hls_aes_only(request, key_acquisition_url)
            asset.delivery_policy_link(delivery_policy)
          end
        rescue => e
          policy.delete  if policy
          asset.delete   if asset
          locator.delete if locator
          program.delete if program
          content_key.delete if content_key
          delivery_policy.delete if delivery_policy
          raise e
          return nil
        end
        return program
      end

      def get(request, program_id=nil)
        if program_id.nil?
          res = request.get('Programs')
          results = []
          if res["d"]
            res["d"]["results"].each do |a|
              results << Program.new(request, a)
            end
          end
        else
          res = request.get("Programs('#{program_id}')")
          results = nil
          if res["d"]
            results = Program.new(request, res["d"])
          end
        end
        results
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
      files = []
      url = "Assets('#{CGI.escape(self.AssetId)}')/Files"
      res = @request.get(url)
      res["d"]["results"].each do |v|
        files << AssetFile.new(@request, v)
      end
      files
    end
    
    def locators
      locators = []
      url = "Assets('#{CGI.escape(self.AssetId)}')/Locators"
      res = @request.get(url)
      res["d"]["results"].each do |v|
        locators << Locator.new(@request, v)
      end
      locators
    end

    def delivery_policies
      delivery_policies = []
      url = "Assets('#{CGI.escape(self.AssetId)}')/DeliveryPolicies"
      res = @request.get(url)
      res["d"]["results"].each do |v|
        delivery_policies << AssetDeliveryPolicy.new(@request, v)
      end
      delivery_policies
    end
    
    def start
      raise 'Program not in stopped state - start not attempted' if self.State != 'Stopped'
      res = @request.post("Programs('#{CGI.escape(self.Id)}')/Start", {})
    end

    def stop
      raise 'Program not in running state - stop not attempted' if self.State != 'Running'
      res = @request.post("Programs('#{CGI.escape(self.Id)}')/Stop", {})
    end

    def delete
      res = @request.delete("Programs('#{self.Id}')")
    end

    def content_key_link(content_key)
      @request.post("Programs('#{CGI.escape(self.Id)}')/$links/ContentKeys", {uri: content_key.__metadata['uri']})
    end

    def delivery_policy_link(asset_delivery_policy)
      @request.post("Programs('#{CGI.escape(self.Id)}')/$links/DeliveryPolicies", {uri: channel_delivery_policy.__metadata['uri']})
    end

  end

end
