module AzureMediaService
  class Program < Model::Base

    class << self

      def create(request, channel_id, name, description='null', manifest_name='null', locator_id=nil, archive_window='PT6H')
        begin
          policy   = AccessPolicy.create(request, 'Policy', 5256000, 1)
          asset    = Asset.create(request, name)
          locators = Locator.create(request, policy['Id'], asset['Id'], 2, locator_id)
          post_body = {
            "ChannelId"           => channel_id,
            "AssetId"             => asset['Id'],
            "Name"                => name,
            "Description"         => description,
            "ManifestName"        => manifest_name,
            "ArchiveWindowLength" => archive_window,
            "Created"             => "0001-01-01T00:00:00",
            "LastModified"        => "0001-01-01T00:00:00",
            "State"               => 'Creating'
          }
          puts "INFO: Creating program '#{name}'..."
          program = self.create_response(request, request.post('Programs', post_body))

          return program
        rescue => e
          puts "ERROR: Exception creating program #{name}: #{e.message} #{e.backtrace}"
        end
        return nil
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
      begin
        channel_id     = self['ChannelId'] 
        name           = self['Name']
        description    = self['Description']
        manifest_name  = self['ManifestName']
        archive_window = self['ArchiveWindowLength']
        locator_id     = nil
        self.locators.each do |locator|
          locator_id = locator['Id']
        end
        puts "INFO: Resetting with name:#{name} manifest:#{manifest_name} & locator:#{locator_id}"
        asset = Asset.get(@request, self['AssetId'])
        self.delete
        asset.delete
        program = Program.create(@request, channel_id, name, description, manifest_name, locator_id, archive_window)
        return program
      rescue => e
        puts "ERROR: Exception reset program #{name}: #{e.message} #{e.backtrace}"
      end
      return nil
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

    def start
      begin 
        raise 'Program not in stopped state - start not attempted' if self.State != 'Stopped'
        puts "INFO: Starting program #{self.Name}"
        res = @request.post("Programs('#{CGI.escape(self.Id)}')/Start", {})
      rescue => e
        puts "ERROR: Failed to start program '#{self.Name}': #{e.message}"
      end
      res
    end

    def stop
      begin 
        raise 'Program not in running state - stop not attempted' if self.State != 'Running'
        puts "INFO: Stopping program #{self.Name}"
        res = @request.post("Programs('#{CGI.escape(self.Id)}')/Stop", {})
      rescue => e
        puts "ERROR: Failed to stop program '#{self.Name}': #{e.message}"
      end
      res
    end

    def delete
      begin 
        res = @request.delete("Programs('#{self.Id}')")
        #clear_cache
      rescue => e
        puts "ERROR: Failed to delete program '#{self.Name}': #{e.message}"
      end
      res
    end

    def content_key_link(content_key)
      @request.post("Programs('#{CGI.escape(self.Id)}')/$links/ContentKeys", {uri: content_key.__metadata['uri']})
    end

    def delivery_policy_link(asset_delivery_policy)
      @request.post("Programs('#{CGI.escape(self.Id)}')/$links/DeliveryPolicies", {uri: channel_delivery_policy.__metadata['uri']})
    end

  end

end
