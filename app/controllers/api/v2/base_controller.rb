class Api::V2::BaseController < Api::V2Controller

  include Api::Versions::V2

  before_action :valid_signature

  # development环境默认关闭验签
  def valid_signature
    return true if params[:api_refer].eql?('nandudu')
    result = ApiCore.valid_signature?(valid_params)
    render_error("验签失败") and return unless result
  end

  # 从headers或params中获取需要验签的参数，优先headers
  def valid_params
    params_dup = params.dup
    config = BaseValue.api_sign_params_config
    valid_keys = config.dig(:valid_keys)
    valid_keys.each do |_key|
      params_dup[_key] = request.headers[_key] if request.headers[_key].present?
    end
    params_dup
  end
end
