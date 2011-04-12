module ObjectBouncer
  module Doorman
    module ClassMethods
      def overwrite_initialize
        class_eval do
          unless method_defined?(:objectbouncer_initialize)
            define_method(:objectbouncer_initialize) do |*args, &block|
              original_initialize(*args, &block)
              @policies = self.class.policies
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

      def policies=(hash)
        @policies = hash
      end

      def policies
        @policies
      end

      def blank_policy_template
        { :if => [], :unless => [] }
      end

      def enforced?
        ObjectBouncer.enforced?
      end

      def current_user=(user)
        @current_user = user
      end

      def current_user
        @current_user
      end

      def as(accessee)
        new_klass = self.clone
        new_klass.table_name = self.table_name if respond_to?(:table_name)
        if respond_to?(:connection_handler)
          new_klass.establish_connection self.connection_handler.connection_pools[name].spec.config
        end
        new_klass.instance_eval do
          include ObjectBouncer::Doorman
        end
        new_klass.policies = self.policies
        new_klass.current_user = accessee
        new_klass.apply_policies
        new_klass
      end

      def door_policy(&block)
        @policies = {}
        yield
        apply_policies
      end

      def deny(method, options = {})
        policies[method] ||= blank_policy_template
        if options.has_key?(:if)
          policies[method][:if] << options[:if]
        elsif options.has_key?(:unless)
          policies[method][:unless] << options[:unless]
        else
          policies[method][:if].unshift(Proc.new{ true == true })
        end
      end

      def apply_policies
        policies.keys.each do |method|
          protect_method!(method)
        end
      end

      def protect_method!(method)
        renamed_method = "#{method}_without_objectbouncer".to_sym
        if method_defined?(method)
          return if method_defined?(renamed_method)
          alias_method renamed_method, method
          define_method method do |*args, &block|
            if call_denied?(method, *args)
              raise ObjectBouncer::PermissionDenied.new
            else
              send(renamed_method, *args, &block)
            end
          end
        end

      end
    end
  end
end
