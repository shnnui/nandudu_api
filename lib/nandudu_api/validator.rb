module ReocarApi
  class ReocarApiValidator < Apipie::Validator::BaseValidator

    VALIDATE_TYPE = [
      :numeric, :uuid, :date_time, :boolean, :email, :phone, :longitude,
      :latitude, :uuids, :new_string
    ]

    MOBILE_REGEX = /^1[3456789]\d{9}$/

    def initialize(param_description, argument)
      @description = super(param_description)
      @type = argument
    end

    def validate(value)
      unless @description.required
        return true if (value.blank? || !!(value =~ /^(\"\")|(\'\')$/))
      end

      return false if value.nil?

      case @type
      when :longitude
        value.is_number? && value.to_f > -180 && value.to_f < 180
      when :latitude
        value.is_number? && value.to_f > -90 && value.to_f < 90
      when :numeric
        !!(is_number?(value))
      when :uuid
        !!UUID.validate(value)
      when :uuids
        value.to_s.to_array.all?{|x| UUID.validate(x)}
      when :date_time
        !!(Time.parse(value.to_s)) rescue false
      when :boolean
        value.to_s.downcase.in?(['true', 'false'])
      when :phone
        !!(value =~ MOBILE_REGEX)
      when :email
        !!(value =~ /^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,4}$/i)
      when :new_string
        true
      end
    end

    def is_number?(value)
      true if Float(value) rescue false
    end

    def self.build(param_description, argument, options, block)
      if argument.in?(VALIDATE_TYPE)
        self.new(param_description, argument)
      end
    end

    def description
      I18n.t("format.required") + I18n.t("type.#{@type}").to_s
    end
  end
end
