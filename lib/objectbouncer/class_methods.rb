module ObjectBouncer
  module Doorman
    module ClassMethods

      def ignoring_added_methods
        ignoring_added_methods = @ignoring_added_methods
        @ignoring_added_methods = true
        yield
      ensure
        @ignoring_added_methods = ignoring_added_methods
      end

      def ignoring_added_methods?
        @ignoring_added_methods
      end

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

      def apply_policies(key = nil)
        if key && policies.keys.include?(key)
          protect_method!(key, force = true)
        else
          policies.keys.each do |method|
            protect_method!(method)
          end
        end
      end

      def protect_method!(method, force = false)
        if method_defined?(method)
          renamed_method = "#{method}_without_objectbouncer".to_sym
          new_method     = "#{method}_with_objectbouncer".to_sym
          unless method_defined?(new_method)
            define_method new_method do |*args, &block|
              if call_denied?(method, *args)
                raise ObjectBouncer::PermissionDenied.new
              else
                send(renamed_method, *args, &block)
              end
            end
          end
          if instance_method(method) != instance_method(new_method)
            alias_method renamed_method, method
            alias_method method, new_method
          end
        end
      end

      def method_added(name)
        return if ignoring_added_methods?
        Thread.exclusive do
          ignoring_added_methods do
            overwrite_initialize if name == :initialize
            apply_policies(name) if policies && policies.keys.include?(name)
          end
        end
      end

    end
  end
end
