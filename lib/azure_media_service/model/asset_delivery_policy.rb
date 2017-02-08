module AzureMediaService
  class AssetDeliveryPolicy < Model::Base

    Protocol = {
      None:            0x0,
      SmoothStreaming: 0x1,
      Dash:            0x2,
      HLS:             0x4,
      Hds:             0x8,
      All:             0xFFFF
    }

    PolicyType = {
      None:                      0,
      Blocked:                   1,
      NoDynamicEncryption:       2,
      DynamicEnvelopeEncryption: 3,
      DynamicCommonEncryption:   4
    }

    ConfigurationKey = {
      None:                           0,
      EnvelopeKeyAcquisitionUrl:      1,
      EnvelopeBaseKeyAcquisitionUrl:  2,
      EnvelopeEncryptionIVAsBase64:   3,
      PlayReadyLicenseAcquisitionUrl: 4,
      PlayReadyCustomAttributes:      5,
      EnvelopeEncryptionIV:           6
    }


    class << self
      def create_hls_aes_only(request, key_delivery_base_url)
        body = {
          "Name" => 'AssetDeliveryPolicy EnvelopeEncryption (HLS)',
          "AssetDeliveryProtocol" => 0x4,
          "AssetDeliveryPolicyType" => 3,
          "AssetDeliveryConfiguration" => [{ Key: 2, Value: key_delivery_base_url}].to_json
        }
        create_response(request, request.post("AssetDeliveryPolicies", body))
      end

      def get(request, asset_delivery_policy_id=nil)
        if asset_delivery_policy_id.nil?
          res = request.get('AssetDeliveryPolicies')
          results = []
          if res["d"]
            res["d"]["results"].each do |adp|
              results << AssetDeliveryPolicy.new(request, adp)
            end
          end
        else
          res = request.get("AssetDeliveryPolicies('#{asset_delivery_policy_id}')")
          results = nil
          if res["d"]
            results = AssetDeliveryPolicy.new(request, res["d"])
          end
        end
        results
      end

    end

    def delete
      begin
        res = @request.delete("AssetDeliveryPolicies('#{self.Id}')")
      rescue => e
        raise MediaServiceError.new(e.message)
      end
      res
    end
  end
end
