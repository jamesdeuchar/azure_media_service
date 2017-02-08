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

    def create_program(name, description=nil, manifest_name=nil, locator_id=nil, duration=nil, key_acquisition_domain=nil)
      Program.create(@request, self['Id'], name, description, manifest_name, locator_id, duration, key_acquisition_domain)
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
      raise 'Channel not in stopped state - start not attempted' if self.State != 'Stopped'
      res = @request.post("Channels('#{CGI.escape(self.Id)}')/Start", {})
    end

    def stop
      raise 'Channel not in running state - stop not attempted' if self.State != 'Running'
      res = @request.post("Channels('#{CGI.escape(self.Id)}')/Stop", {})
    end

    def reset
      raise 'Channel not in running state - reset not attempted' if self.State != 'Running'
      res = @request.post("Channels('#{CGI.escape(self.Id)}')/Reset", {})
    end
    
    def delete
      res = @request.delete("Channels('#{self.Id}')")
    end

  end

end
