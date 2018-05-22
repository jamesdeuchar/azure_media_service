module AzureMediaService
  class Config
    UPLOAD_LIMIT_SIZE = 4194304 # 4MB
    READ_BUFFER_SIZE  = 4000000

    MEDIA_URI = "https://%{account}.restv2.%{region}.media.azure.net/api/"
    TOKEN_URI = "https://login.microsoftonline.com/%{tenant}/oauth2/token"

    GUID_PREFIX = { 'Channel'   => 'nb:chid:UUID',
                    'Program'   => 'nb:pgid:UUID',
                    'Locator'   => 'nb:lid:UUID',
                    'Asset'     => 'nb:cid:UUID',
                    'Operation' => 'nb:opid:UUID',
                    'ContentKey' => 'nb:kid:UUID',
                    'ContentKeyAuthorizationPolicyOption' => 'nb:ckpoid:UUID',
                    'AssetDeliveryPolicy' => 'nb:adpid:UUID' }

  end
end
