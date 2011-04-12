module ObjectBouncer
  module Doorman
    module ClassMethods
      def overwrite_initialize
        class_eval do
          unless method_defined?(:objectbouncer_initialize)
            define_method(:objectbouncer_initialize) do |*args, &block|
              original_initialize(*args, &block)
              @policies = self.class.instance_policies
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


      def all_policies
        @all_policies || {}
      end

      def instance_policies
        all_policies[:instance] || {}
      end

      def singleton_policies
        all_policies[:singleton] || {}
      end

      def policies
        singleton_policies || {}
      end

      def blank_policy_template
        { :if => [], :unless => [] }
      end

      def enforced?
        ObjectBouncer.enforced?
      end

      def all_policies=(val)
        @all_policies = val
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
        new_klass.all_policies = self.all_policies
        new_klass.current_user = accessee
        new_klass.apply_policies
        #require 'ruby-debug'; debugger
        #new_klass.create
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
        @all_policies = { :singleton => {}, :instance => {} }
        yield
        apply_policies
      end

      def deny(method, options = {})
        scope = options[:singleton] ? :singleton : :instance
        @all_policies[scope][method] ||= blank_policy_template
        if options.has_key?(:if)
          @all_policies[scope][method][:if] << options[:if]
        elsif options.has_key?(:unless)
          @all_policies[scope][method][:unless] << options[:unless]
        else
          @all_policies[scope][method][:if].unshift(Proc.new{ true == true })
        end
      end

      def apply_policies
        policies.keys.each do |method|
          protect_method!(method, true)
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
          return if respond_to?(renamed_method)
          def_str = "class << self; alias_method :#{renamed_method.to_s}, :#{method.to_s}; end"
          #def_str = "alias_method :#{renamed_method.to_s}, :#{method.to_s}"
          #self.instance_eval(def_str)
          #self.class_eval(def_str)
          #require 'ruby-debug'; debugger
          method_def = %Q{
            class << self
              alias_method :#{renamed_method.to_s}, :#{method.to_s}
              define_method :#{method.to_s} do |*args, &block|
                require 'ruby-debug'; debugger
                if call_denied?(:#{method.to_s}, *args)
                  raise ObjectBouncer::PermissionDenied.new
                else
                  require 'ruby-debug'; debugger
                  send(:#{renamed_method.to_s}, *args, &block)
                end
              end
            end}

          self.instance_eval(method_def)

        end
      end
    end
  end
end
