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
      self.class.policies.keys.each do |method|
        self.class.protect_method!(method)
      end
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
        if policies = self.class.policies[meth]
          if !policies[:deny][:unless].empty?
            return false if policies[:deny][:unless].detect{|policy| policy.call(current_user, @object, *args) rescue nil}
            return true
          end
          return true if policies[:deny][:if].detect{|policy| policy.call(current_user, @object, *args) rescue nil}
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
