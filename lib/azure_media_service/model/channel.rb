module AzureMediaService
  class Channel < Model::Base

    class << self

      def create(name, options=0)
        post_body = {
          "Name" => name,
          "Options" => options
        }
        create_response(service.post("Channels", post_body))
      end
      
    end

    def create_program(name, description=nil, manifest_name=nil, locator_id=nil, duration=nil)
      Program.create(@request, self['Id'], name, description, manifest_name, locator_id, duration)
    end
      
    def programs
      programs = []
      _uri = URI.parse(self.Programs["__deferred"]["uri"])
      url = _uri.path.gsub('/api/','')
      res = @request.get(url)
      res["d"]["results"].each do |v|
        programs << Program.new(@request, v)
      end
      programs
    end

    def inputs
      inputs = []
      if inputs.empty?
        self.Input["Endpoints"]['results'].each do |input|
          inputs << input
        end
      end
      inputs
    end
    
    def start
      begin 
        raise 'Channel not in stopped state - start not attempted' if self.State != 'Stopped'
        puts "INFO: Starting channel #{self.Name}"
        res = @request.post("Channels('#{CGI.escape(self.Id)}')/Start", {})
      rescue => e
        puts "ERROR: Failed to start channel '#{self.Name}': #{e.message}"
      end
      res
    end

    def stop
      begin 
        raise 'Channel not in running state - stop not attempted' if self.State != 'Running'
        puts "INFO: Stopping channel #{self.Name}"
        res = @request.post("Channels('#{CGI.escape(self.Id)}')/Stop", {})
      rescue => e
        puts "ERROR: Failed to stop channel '#{self.Name}': #{e.message}"
      end
      res
    end

    def reset
      begin 
        res = @request.post("Channels('#{CGI.escape(self.Id)}')/Reset", {})
      rescue => e
        puts "ERROR: Failed to reset channel '#{self.Name}': #{e.message}"
      end
      res
    end
    
    def delete
      begin 
        res = @request.delete("Channels('#{self.Id}')")
        clear_cache
      rescue => e
        puts "ERROR: Failed to delete channel '#{self.Name}': #{e.message}"
      end
      res
    end

  end

end
