class Api::V1::PushDataController < ActionController::Base

  def index
    Util.info "params: #{params}"
    payload = params[:payload]
    unless payload.is_a?(String)
      Util.error "payload is not string"
      Util.error payload["file"] rescue '没有文件'
      Util.error payload[:fileCode] rescue '没有文件代码'
      file = payload[:file] rescue nil
      if file.present?
        file = file.gsub('/home/app/', '/nandudu_data/nandudu/shared/')
        payload = {
          fileCode: payload[:fileCode],
          objId: payload["objId"],
          attachment: File.new(file, 'rb'),
          file: file,
          attachmentName: URI.encode(File.basename(file))
        }
        Util.info payload
      end
    end
    result = begin
      request = RestClient::Request.new(
        method: params[:send_way],
        url: params[:url],
        payload: payload,
        headers: params[:headers],
        timeout: 900,
        open_timeout: 10,
        verify_ssl: false
      )
      data = request.execute
      Util.info "data: #{data}"
      response = JSON.parse(data)
      {
        is_sent: true,
        message: '已发起API请求',
        response: response,
        result: data
      }
    rescue => ex
      Util.error(__method__){ex}
      {
        is_sent: false,
        message: "出错了：#{ex.try(:message)}",
        result: {err_msg: ex.try(:message)}.to_json
      }
    end
    render json: result
  end

end