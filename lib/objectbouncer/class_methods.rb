module ObjectBouncer
  module Doorman
    module ClassMethods
      def overwrite_initialize
        class_eval do
          unless method_defined?(:objectbouncer_initialize)
            define_method(:objectbouncer_initialize) do |*args, &block|
              original_initialize(*args, &block)
              apply_policies
              self
            end
          end

          if instance_method(:initialize) != instance_method(:objectbouncer_initialize)
            alias_method :original_initialize, :initialize
            alias_method :initialize, :objectbouncer_initialize
          end
        end
      end


      def policies
        @policies || {}
      end

      def blank_policy_template
        {
          :allow => { :if => [], :unless => [] },
          :deny  => { :if => [], :unless => [] }
        }
      end

      def enforced?
        ObjectBouncer.enforced?
      end

      def object_bouncer_settings
        @policies
      end

      def object_bouncer_settings=(settings)
        @policies = settings
      end

      def current_user=(user)
        @current_user = user
      end

      def current_user
        @current_user
      end

      def as(accessee)
        new_klass = self.clone
        new_klass.table_name = self.table_name
        new_klass.establish_connection self.connection_handler.connection_pools[name].spec.config
        new_klass.instance_eval do
          include ObjectBouncer::Doorman
        end
        new_klass.object_bouncer_settings = self.object_bouncer_settings
        new_klass.current_user = accessee
        new_klass
      end

      def protected_class(class_name)
        names = class_name.split('::')
        names.shift if names.empty? || names.first.empty?
        constant = Object
        names.each do |name|
          constant = constant.const_get(name, false) || constant.const_missing(name)
        end
        @protected_class = constant
      end

      def door_policy(&block)
        @policies = {}
        yield
      end

      def deny(method, options = {})
        protect_method!(method, options[:singleton])
        @policies[method] ||= blank_policy_template
        if options.has_key?(:if)
          @policies[method][:deny][:if] << options[:if]
        elsif options.has_key?(:unless)
          @policies[method][:deny][:unless] << options[:unless]
        else
          @policies[method][:deny][:if].unshift(Proc.new{ true == true })
        end
      end

      def protect_method!(method, singleton = false)
        renamed_method = "#{method}_without_objectbouncer".to_sym
        if !singleton && method_defined?(method)
          return if method_defined?(renamed_method)
          alias_method renamed_method, method
          define_method method do |*args, &block|
            if call_denied?(method, *args)
              raise ObjectBouncer::PermissionDenied.new
            else
              send(renamed_method, *args, &block)
            end
          end
        elsif singleton || respond_to?(method)
          alias_method renamed_method, method
        else
        end
      end

    end
  end
end
