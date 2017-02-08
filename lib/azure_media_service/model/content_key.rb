module AzureMediaService
  class ContentKey < Model::Base

    ContentKeyTypes = {
      CommonEncryption:        0,
      StorageEncryption:       1,
      ConfigurationEncryption: 2,
      UrlEncryption:           3,
      EnvelopeEncryption:      4
    }

    class << self
      def create_open_aes(request)
        ckapo = ContentKeyAuthorizationPolicyOption.create(request, 'Open Mode AES', 2, nil, 
                                                           [{ "Name":"HLS Open Authorization Policy", "KeyRestrictionType":0, "Requirements": nil }] )
        ckap = ContentKeyAuthorizationPolicy.create(request, 'Authorization Policy')
        ckap.option_link(ckapo)
        protection_key_id = self.get_protection_key_id(request)['d']['GetProtectionKeyId']
        protection_key = self.get_protection_key(request, "'#{protection_key_id}'")['d']['GetProtectionKey']
        x509 = OpenSSL::X509::Certificate.new(Base64.decode64(protection_key))
        public_key = x509.public_key
        content_key = SecureRandom.random_bytes(16)
        encrypted_content_key = Base64.strict_encode64(public_key.public_encrypt(content_key, OpenSSL::PKey::RSA::PKCS1_OAEP_PADDING))
        cipher = OpenSSL::Cipher.new('AES-128-ECB')
        cipher.encrypt
        cipher.key = content_key
        cipher.padding = 0
        encrypt_data = ""
        encrypt_data << cipher.update(protection_key_id[0,16])
        encrypt_data << cipher.final
        check_sum = Base64.strict_encode64(encrypt_data[0,8])
        post_body = {
           "Id"                    => "nb:kid:UUID:#{SecureRandom.uuid}",
           "ContentKeyType"        => 4,
           "EncryptedContentKey"   => encrypted_content_key,
           "ProtectionKeyId"       => protection_key_id,
           "ProtectionKeyType"     => 0,
           "Checksum"              => check_sum,
           "Name"                  => 'BT Azure Content Key',
           "AuthorizationPolicyId" => ckap['Id']
        }
        self.create_response(request, request.post("ContentKeys", post_body))
      end

      def get(content_key_id=nil)
        if content_key_id.nil?
          res = request.get('ContentKeys')
          results = []
          if res["d"]
            res["d"]["results"].each do |ck|
              results << ContentKey.new(request, ck)
            end
          end
        else
          res = request.get("ContentKeys('#{content_key_id}')")
          results = nil
          if res["d"]
            results = ContentKey.new(request, res["d"])
          end
        end
        results
      end

      def get_protection_key_id(request, content_key_type=4)
        request.get("GetProtectionKeyId", { contentKeyType: content_key_type })
      end

      def get_protection_key(request, protection_key_id)
        request.get("GetProtectionKey", { ProtectionKeyId: protection_key_id })
      end

    end

    def add_authorization_policy(policy_id)
      res = @request.put("ContentKeys('#{CGI.escape(self.Id)}')", {AuthorizationPolicyId: policy_id})
    end

    # GetKeyDeliveryUrl
    #
    # @params key_delivery_type 1: PlayReady license 2: EnvelopeEncryption
    #
    def get_key_delivery_url(key_delivery_type)
      @request.post("ContentKeys('#{CGI.escape(self.Id)}')/GetKeyDeliveryUrl", {KeyDeliveryType: key_delivery_type})
    end

    def delete
      begin
        res = @request.delete("ContentKeys('#{self.Id}')")
        clear_cache
      rescue => e
        raise MediaServiceError.new(e.message)
      end
      res
    end
  end
end
