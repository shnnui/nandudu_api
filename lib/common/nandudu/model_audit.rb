module Nandudu
  module ModelAudit

    module VersionCollector
      attr_accessor :cascade_versions

      # 暂不支持递归
      def collect_versions
        versions = (RequestStore.store[:cascade_versions] ||= [])
        yield
      rescue => err
      ensure
        RequestStore.delete(:cascade_versions)
        if err
          raise err
        else
          return versions
        end
      end
    end

    def self.included(base)
      # 移除model column类型信息, 下次请求会重新加载
      # base.reset_column_information
      options = base.try(:hook_model_audit) || {}
      (options[:meta] ||= {})[:versioning_item] = ->(item){item}

      base.include VersionCollector

      if base.respond_to? :not_track_column
        options[:skip] ||= []
        options[:skip].concat base.not_track_column
      end
      Util.info options
      base.send(:has_paper_trail, options.merge(class_name: '::NanduduVersion'))
    end

    def method_missing(method, *arguments, &block)
      if [:created_by, :updated_by].include?(method)
        cache_key = "#{self.class.name}_#{self.id}_#{self.updated_at}_#{method}"
        Rails.cache.fetch(cache_key, expires_in: 24.hours) do
          user = public_send("#{method}_user")
          "#{user.try(:full_name)}"
        end
      else
        super
      end
    end

    def created_by_user
      created_by_id && User.find(created_by_id)
    end

    def updated_by_user
      updated_by_id && User.find(updated_by_id)
    end

    def created_by_id
      first_version = self.versions.first
      first_version && first_version.whodunnit
    end

    def updated_by_id
      last_version = self.versions.last
      last_version && last_version.whodunnit
    end

    def object_on_create
      version =
        if versions.loaded?
          versions.find { |v| v.event == 'create' }
        else
          versions.find_by(event: 'create')
        end
      return if version.blank?
      next_able_object(version)
    end

    def first_value_of_field(field)
      field = field.to_s.to_sym
      self.versions.each do |v|
        changes = v.changeset[field]
        next if changes.blank?
        return changes[1] if changes[0].blank? && changes[1].present?
        return changes[0] if changes[0].present?
      end
      nil
    end

    # 返回下一个可用的对象
    # 例如：获取创建时的对象
    def next_able_object(version)
      return if version.blank?
      _next_version = version.next
      return if _next_version.blank?
      able_object = _next_version.reify
      if able_object.try(:id).blank?
        able_object = next_able_object(_next_version)
      end
      able_object
    end
  end
end
