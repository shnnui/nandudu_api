module ParamsTp
  module_function

  # NOTE: all keys must use symbol
  # distinguish different namespace
  NAME_TYPE = {
    request_params: [:from_api, :api_refer, :scheme]
  }.freeze

  # example:
  #   { request_params: [:from_api, :api_refer] }
  # methods:
  #   def init_request_params(params = {})
  #   def request_params(k_array = [])
  #   def request_params_from_api(default_value = nil)
  #   def request_params_api_refer(default_value = nil)
  #   def request_params_scheme(default_value = nil)
  NAME_TYPE.each do |name, value|

    # initialize:
    #   ParamsTp.init_request_params(from_api: true, api_refer: 'ios')
    # return:
    #   NAME_TYPE[:request_params]
    define_method "init_#{name.to_s}" do |params = {}|
      params_namespace(name).merge!(params.slice(*value))
    end

    # get name_type all value or by array of symbol
    #   ParamsTp.request_params or ParamsTp.request_params([:from_api, :api_refer])
    # return:
    #   {:from_api=>true, :api_refer=>"ios"}
    define_method name.to_s do |k_array = []|
      if k_array.blank?
        params_namespace(name)
      else
        params_namespace(name).slice(*k_array)
      end
    end

    # get value by one key--from_api
    #   ParamsTp.request_params_from_api
    # return:
    #   true
    value.each do |key|
      define_method "#{name}_#{key}" do |default_value = nil|
        params_namespace(name)[key] || default_value
      end
    end
  end

  def params_namespace(name)
    RequestStore.store[name] ||= {}
  end
end
