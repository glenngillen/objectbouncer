module ObjectBouncer
  def self.enforce!
    @enforce = true
  end

  def self.unenforce!
    @enforce = false
  end

  def self.enforced?
    @enforce
  end

  module Doorman

    def self.included(klass)
      klass.extend ClassMethods
    end

    module ClassMethods
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

      def object_bouncer_settings
        [@lockdown, @policies]
      end

      def object_bouncer_settings=(settings)
        @lockdown, @policies = settings
      end

      def current_user=(user)
        @current_user = user
      end

      def current_user
        @current_user
      end

      def door_policy(&block)
        @lockdown = false
        @policies = {}
        yield
      end

      def lockdown!
        @lockdown = true
      end

      def lockdown?
        @lockdown
      end

      def enforced?
        ObjectBouncer.enforced?
      end

      def allow(method, options = {})
        protect_method!(method)
        @policies[method] ||= blank_policy_template
        if options.has_key?(:if)
          @policies[method][:allow][:if] << options[:if]
        elsif options.has_key?(:unless)
          @policies[method][:allow][:unless] << options[:unless]
        else
          @policies[method][:allow][:if].unshift(Proc.new{ true == true })
        end
      end

      def deny(method, options = {})
        protect_method!(method)
        @policies[method] ||= blank_policy_template
        if options.has_key?(:if)
          @policies[method][:deny][:if] << options[:if]
        elsif options.has_key?(:unless)
          @policies[method][:deny][:unless] << options[:unless]
        else
          @policies[method][:deny][:if].unshift(Proc.new{ true == true })
        end
      end

      def policies
        @policies
      end

      def blank_policy_template
        {
          :allow => { :if => [], :unless => [] },
          :deny  => { :if => [], :unless => [] }
        }
      end

      def protect_method!(method)
        renamed_method = "#{method}_without_objectbouncer".to_sym
        alias_method renamed_method, method
        define_method(method) do |*args, &block|
          if call_allowed?(method, *args)
            send(renamed_method, *args, &block)
          elsif call_denied?(method, *args)
            raise ObjectBouncer::PermissionDenied.new
          else
            send(renamed_method, *args, &block)
          end
        end
      end

    end

    # def initialize(accessee, object)
    #   @accessee = accessee
    #   @object = object
    #   super()
    #   self
    # end


    # def method_missing(meth, *args, &block)
    #   if respond_to?(meth)
    #     raise "You need to define an access policy if you include ObjectBounce::Doorman" if self.class.policies.nil? or self.class.policies.empty?
    #     if call_allowed?(meth, *args) #       @object.send(meth, *args, &block)
    #     elsif call_denied?(meth, *args)
    #       raise ObjectBouncer::PermissionDenied.new
    #     else
    #       @object.send(meth, *args, &block)
    #     end
    #   else
    #     super
    #   end
    # end

    # def respond_to?(meth)
    #   @object.respond_to?(meth)
    # end

    private
      def current_user
        self.class.current_user
      end

      def call_allowed?(meth, *args)
        if current_user.nil? && enforced?
          raise ObjectBouncer::ArgumentError.new("Need to provide a user to execute this action as, e.g., #{self.class.to_s}.as(@a_user_here).#{meth.to_s}")
        end
        return true if current_user.nil?
        if policies = self.class.policies[meth]
          return true if !policies[:allow][:unless].empty? && !policies[:allow][:unless].detect{|policy| policy.call(current_user, @object, *args) rescue nil}
          return true if policies[:allow][:if].detect{|policy| policy.call(current_user, @object, *args) rescue nil}
          return true if policies[:deny][:unless].detect{|policy| policy.call(current_user, @object, *args) rescue nil}
        end
      end

      def call_denied?(meth, *args)
        return true if self.class.lockdown?
        if policies = self.class.policies[meth]
          return true if policies[:allow][:unless].detect{|policy| policy.call(current_user, @object, *args) rescue nil}
          return true if policies[:deny][:if].detect{|policy| policy.call(current_user, @object, *args) rescue nil}
          return true if !policies[:deny][:unless].empty? && !call_allowed?(meth)
        end
      end

      def enforced?
        ObjectBouncer.enforced?
      end

      def object=(val)
        @object = val
      end

  end
end
