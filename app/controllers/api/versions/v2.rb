# 用于共享V2共同结构和描述信息
# 规避apipie多版本下资源定义不能继承问题，其它方法如下
# @controller.superclass.apipie_resource_descriptions.first._params_args.each do |x|
#   param *(x.take(4))
# end
module Api::Versions
  module V2
    extend ActiveSupport::Concern

    included do
      short_msg = case self.name
                  when 'Api::V2::PurchasesController'
                    '南度度与南网电子交易平台对接API'
                  else
                    '暂无描述'
                  end

      resource_description do
        api_version "v2"
        app_info "V2版本正在开发"

        param :api_refer, String, 'API请求来源', required: false
        #param :auth_token, String, '登陆后获取到的token，建议放到header的Authorization中请求', required: false

        short short_msg
      end
    end
  end
end
