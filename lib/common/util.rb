# coding: utf-8

# 公共函数库

class Util

  COLOR_GRAY    = 30
  COLOR_RED     = 31
  COLOR_GREEN   = 32
  COLOR_YELLOW  = 33
  COLOR_BLUE    = 34
  COLOR_WHITE   = 37

  class << self
    # 解析base64文件
    def splitBase64(uri)
      if uri.match(%r{^data:(.*?);(.*?),(.*)$})
        return {
          type:      $1, # "image/png"
          encoder:   $2, # "base64"
          data:      $3, # data string
          extension: $1.split('/')[1] # "png"
        }
      end
    end

    # 功能同open，增加临时文件删除逻辑
    def open_uri(url)
      file = open(url)
      file.unlink if file.is_a?(Tempfile)
      file
    end

    # 写日志
    def write_log(name, content)
      File.open("./log/#{name}.log",'ab'){|x| x.write "#{Time.current} #{content}\n" }
    end

    # 获取asset资源文件
    def get_asset(name)
      if Rails.application.assets
        asse = Rails.application.assets[name]
        return asse.to_s if asse
      end
      asse = Rails.application.assets_manifest.assets[name]
      return nil unless asse
      return File.binread(File.join(Rails.application.assets_manifest.dir, asse))
    end

    # 单位由元转成分
    def yuan_to_fen(num)
      (num.to_d * 100).to_i
    end

    # 时间小时转为分钟
    def hour_and_minute(datetime)
      datetime = datetime.to_time if datetime.is_a?(Date)
      datetime.hour * 60 + datetime.min
    end

    # 可能的内网地址, 如有特殊IP，直接扩展正则，不建议使用数组是否包含或者字符串是否相等形式判断
    def trusted_proxy?(ip)
      ip =~ /\A127\.0\.0\.1\Z|\A(10|172\.(1[6-9]|2[0-9]|30|31)|192\.168)\.|\A::1\Z|\Afd[0-9a-f]{2}:.+|\Alocalhost\Z|\Aunix\Z|\Aunix:/i
    end

    # 转换key为underscore
    def underscore_key(params)
      Hash[params.map { |k, v| [k.to_s.underscore.to_sym, v] }]
    end

    def valid_image?(filename)
      /\.(gif|jpg|jpeg|png|bmp|GIF|JPG|PNG|BMP)$/ =~ filename.to_s
    end

    # \n\r\t替换\\n\\r\\t
    def gsub_key(options)
      options.gsub("\n", "\\n")
             .gsub("\r", "\\r")
             .gsub("\t", "\\t")
    end

    # default: Strip values of hash just one level
    # param: deep => 表示是否继续处理内层
    def strip_values(hash, deep = false)
      return {} if hash.blank?
      hash.each do |key, value|
        (hash[key] = value.strip and next) if value.is_a?(String)
        (hash[key] = strip_values(hash[key], deep) and next) if deep && value.is_a?(Hash)
      end
    end

    # wash parameter for array values
    def wash_multi_value(value)
      (Array(value) || []) - [""]
    end

    # 将调试信息打到日志上
    def debug(message, color = COLOR_GREEN)
      #Rails.logger.debug("\n  \e\[5;#{color};1m#{message}\e\[0m\n\n")
      Rails.logger.debug("\n\033[#{color}m#{message}\033[0m\n\n")
    end

    # 将调试信息打到日志上
    def info(message, color = COLOR_BLUE)
      Rails.logger.info("\n\033[#{color}m#{message}\033[0m\n\n")
    end

    # Print plain message is better for read on production
    def warn(message, color = COLOR_YELLOW)
      Rails.logger.warn("\n\033[#{color}m#{message}\033[0m\n\n")
    end

    # Print plain message is better for read on production
    def error(message, color = COLOR_RED)
      Rails.logger.error("\n\033[#{color}m#{message}\033[0m\n\n")
    end

    # 截断字符串
    def cut(text, length = 20, tail = "...")
      return '' if text.blank?

      len, text = length, text.gsub(/<\/?[^>]*>|\s+|　/, '')
      (text.reverse!; len /= -1.0; tail = '') if length < 0 # 如果为负数，截取后面
      l, char_array = 0, text.unpack("U*")
      char_array.each_with_index do | c, i |
        l += (c < 127 ? 0.5 : 1)
        (text = (i < char_array.length - 1 ? char_array[0..i].pack("U*") + tail : text); break) if l >= len
      end
      return length < 0 ? text.reverse : text
    end

    def str_to_nomal(str)
      str.to_s.gsub(/<\/?[^>]*>|\s+|　/, '')
    end

    # 仅格式化数组变Hash
    def format_arr_to_hash(arr)
       Hash[ arr.map {|value| [value, value]} ]
    end

    # 生成随机数
    def rand_code(num = 6)
      Array.new(num){rand(0..9)}.join()
    end

    # 生成新的uuid
    def new_uuid
      SecureRandom.uuid
    end

    # 下拉框显示年份
    def select_years
      years = []
      SELECT_YEARS.times do |y|
        years << Time.current.year - SELECT_YEARS/2.round + y
      end
      years
    end

    # 加密文件路径
    def encrypt_file_path(path)
      path_options = BaseValue.base_service_file_download_option
      encrypt_options = {data: path, key: path_options[:key].slice(0,24), iv: path_options[:iv].slice(0,8)}
      encrypt_path = Encryption.des_encrypt("des-ede3-cbc", encrypt_options)
      Base64.encode64(encrypt_path).gsub("\n", "")
    rescue
      nil
    end

    # 解密文件路径
    def decrypt_file_path(path)
      path_options = BaseValue.base_service_file_download_option
      encrypt_options = {data: Base64.decode64(path) , key: path_options[:key].slice(0,24), iv: path_options[:iv].slice(0,8)}
      Encryption.des_decrypt("des-ede3-cbc", encrypt_options)
    rescue
      nil
    end

    # 文件内容,base64格式
    def file_data(path)
      return unless File.exist?(path)
      file = File.new(path)
      extension = File.extname(file)[1..-1]
      mime_type = Mime::Type.lookup_by_extension(extension).to_s
      data = Base64.encode64(file.read).gsub("\n", "")
      "data:#{mime_type};base64,#{data}"
    end

    def base64_image(image)
      Base64.encode64(Rails.application.assets[image].to_s).gsub("\n", '')
    end

    # 用于获取两日期间隔月数
    def months_difference(period_start, period_end)
      period_end = period_end + 1.day
      months = (period_end.year - period_start.year) * 12 + period_end.month - period_start.month - (period_end.day >= period_start.day ? 0 : 1)
      remains = period_end - (period_start + months.month)

      (months + remains/period_end.end_of_month.day).to_f.round(2)
    end

    # 用于缓存处理, int_expires 分钟
    def nandudu_cache(cache_key, int_expires = rand(15..60), &block)
      int_expires ||= 1.day / 1.minutes
      Rails.cache.fetch(cache_key, expires_in: int_expires.minutes) do
        yield if block_given?
      end
    end

    # 将结果缓存在内存中，在http流程中缓存只在请求过程中存在，其它情况下存储在当前线程中
    def thread_cache(key, &block)
      RequestStore.store[key] = RequestStore.store.fetch(key) do
        yield if block_given?
      end
    end

    #wicked_pdf: html转pdf,将img转为base64
    def richtext_img_to_base64_pdf(content)
      if content.present?
        img_src_reg = / src="(.*?)"/
        content.to_s.gsub!(img_src_reg){
          |match|
          src = ''
          base64 = ''
          if match.present?
            src = match.gsub(' src="','').gsub('"','')
          end
          # 兼容本身base64的图片
          if src.include?(';base64')
            base64 = src
          else
            # 中文命名的图片decode解码
            imgUrl = Rails.root.to_s + '/public' + URI::decode(src.to_s)
            base64 = file_data(imgUrl)
          end
          newSrc = " src=\"#{base64}\""
          newSrc
        }
      end
      content
    end

    def boolean_to_str(value)
      if value
        '有'
      else
        '无'
      end
    end

    def boolean_attribute_name(is_true)
      is_true ? "是" : "否"
    end

    # 用于显示hash数据
    def show_hash_info(hash)
      data = []
      hash.each_pair {|key, value| data << "#{key}: #{value}"}
      data.join('<br/>').html_safe
    end

    # 发起request
    def send_request(payload = {}, url = '', send_way = 'post', timeout = 30)
      result = {is_send: false, message: '缺少请求url参数'}
      return result if url.blank?
      Util.info "url: #{url}"
      headers = {
        'Content-type' => 'application/json;mulipart/form-data',
        'Cache-Control' => 'no-cache',
        'Connection' => 'Keep-Alive'
      }
      Util.info "send_way: #{send_way}, url:#{url}"
      request = RestClient::Request.new(
        method: send_way,
        url: url,
        payload: payload,
        headers: headers,
        timeout: timeout,
        open_timeout: 20,
        verify_ssl: false
      )

      data = request.execute
      Util.info "data: #{data}"
      response = JSON.parse(data)
      {
        is_sent: true,
        message: '已发起API请求',
        response: response
      }
    rescue => ex
      Util.error(__method__){ex}
      {
        is_sent: false,
        message: "出错了：#{ex.try(:message)}"
      }
    end


  end
end

# 在helper里面include CoreHelper，即可在Controller、View里面不带前缀使用！
module UtilHelper

  def cut(text, length = 20, tail = "...")
    Util.cut(text, length, tail)
  end

end
