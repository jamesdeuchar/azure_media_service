module AzureMediaService
  class Config
    UPLOAD_LIMIT_SIZE = 4194304 # 4MB
    READ_BUFFER_SIZE  = 4000000

    MEDIA_URI = "https://media.windows.net/api/"
    TOKEN_URI = "https://wamsprodglobal001acs.accesscontrol.windows.net/v2/OAuth2-13"

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
