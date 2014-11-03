require 'openpayu'

SAMPLE_POS_ID = '145227'
SAMPLE_SIGNATURE_KEY = '13a980d4f851f3d9a1cfc792fb1f5e50'

  #This is test credentials. This gem no longer uses OpenPayU

OpenPayU::Configuration.configure do |config|
  config.merchant_pos_id  = SAMPLE_POS_ID
  config.signature_key    = SAMPLE_SIGNATURE_KEY
  config.algorithm        = 'MD5'
  config.service_domain   = 'payu.com'
  config.protocol         = 'https'
  config.env              = 'secure'
  config.order_url        = ''
  config.notify_url       = ''
  config.continue_url     = ''
end
