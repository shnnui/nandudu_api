Apipie.configure do |config|
  config.app_name                = "Nandudu API Doc"
  config.api_base_url            = "/api"
  config.doc_base_url            = "/nandudu_api"
  config.default_version         = "v2"
  config.languages               = ['zh-CN']
  config.default_locale          = "zh-CN"
  # where is your API defined?
  config.api_controllers_matcher = "#{Rails.root}/app/controllers/api/**/*.rb"
  config.authenticate = Proc.new do
    authenticate_or_request_with_http_basic do |username, password|
      username == "nandudu_api_doc" && password == "ndys@1234"
    end
  end
end
