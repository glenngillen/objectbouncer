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

    def with(user)
      self
    end

    def current_user=(user)
      @current_user = user
    end

    def current_user
      @current_user ||= self.class.current_user
    end

    def apply_policies
      policies.keys.each do |method|
        self.class.protect_method!(method)
      end
    end

    def policies
      @policies || self.class.instance_policies
    end

    def self.included(klass)
      klass.extend ClassMethods
      klass.overwrite_initialize
      klass.instance_eval do
        def method_added(name)
          overwrite_initialize if name == :initialize
        end
      end
    end

    private

      def call_denied?(meth, *args)
        if enforced? && current_user.nil?
          raise ObjectBouncer::ArgumentError.new("You need to specify the user to execute the method as. e.g., #{self.class.to_s}.as(@some_user).#{meth.to_s}(....)")
        end
        return false if current_user.nil? && !enforced?
        if meth_policies = policies[meth]
          if !meth_policies[:unless].empty?
            return false if meth_policies[:unless].detect{|policy| policy.call(current_user, @object, *args) rescue nil}
            return true
          end
          return true if meth_policies[:if].detect{|policy| policy.call(current_user, @object, *args) rescue nil}
        end
      end

      def enforced?
        ObjectBouncer.enforced?
      end
  end
end
