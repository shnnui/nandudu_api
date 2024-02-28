require "nandudu_api"
module Api
  class V2Controller < ActionController::Base
    before_action :run_validations
    before_action :init_application

    def api_version; '2'; end

    rescue_from StandardError do |exception|
      Util.error(:ApiStandardError)
      Util.error params
      case exception
      when Apipie::ParamMissing
        text = I18n.t("api.missing_param", param: exception.param.name.to_s)
        Util.error text
        render_error(text, status: 422)
      when Apipie::ParamInvalid
        text = I18n.t("api.invalid_param", param: "#{exception.param} value #{exception.value.inspect}: #{exception.error}")
        Util.error text
        render_error(text, status: 400)
      when ActiveRecord::RecordNotFound
        msg = exception.message

        clazz_name = msg.match(/find\ (.*)\ with/).try(:[], 1)
        clazz = clazz_name.constantize if clazz_name.present?

        msg = "找不到该#{clazz.model_name.human}记录！" if clazz.present?

        render_error(msg, status: 404)
      else
        Util.info exception.try(:backtrace).try(:join, '<br/>')
        msg = Rails.env.production? ? '服务器异常，请联系开发获取帮助！' : exception.message
        render_error(msg, status: 500)
      end
    end

    # header
    #   status integer 标准http状态码
    def render_result(result, header = {})
      dispatch_result(0, result, header)
    end

    # header
    #   status integer 标准http状态码
    def render_error(result, header = {})
      code = 1
      # TODO 根据异常获取错误编号
      # if result < StandardError
      #   code = result.try(:error_code)
      # end
      dispatch_result(code, result, header)
    end

    def paginate_collection(collection, page = 1, per_page = 10)
      return collection if collection.blank?
      @page = params[:page].present? ? params[:page] : page
      @per_page = params[:per_page].present? ? params[:per_page] : per_page
      collection.paginate(page: @page.to_i, per_page: @per_page.to_i)
    end

    private

    def init_application
      request.format = :json # 强制渲染json模板
      ParamsTp.init_request_params(
        from_api: true, api_refer: params[:api_refer], scheme: request.scheme
      )
    end

    # 执行API参数校验，需要将token从header中移到params里
    def run_validations
      params[:auth_token].blank? && (params[:auth_token] = request.authorization)
      apipie_validations if Apipie.configuration.validate == :explicitly
    end

    def dispatch_result(code, result, header)
      result = {message: result} if result.is_a?(String)
      raise '数据必须是Array或Hash！' unless result.respond_to?(:to_a) || result.respond_to?(:as_json)

      data = {code: code}

      if result.class < FastJsonapi::ObjectSerializer
        data.merge!(result)
      else
        data[:data] = result
      end

      render json: data, **header
    end
  end
end
