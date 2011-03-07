module ObjectBouncer
  module Doorman

    def self.included(klass)
      klass.extend ClassMethods
    end

    module ClassMethods
      def door_policy(&block)
        @lockdown = false
        @policies = {}
        yield
      end

      def lockdown
        @lockdown = true
      end

      def lockdown?
        @lockdown
      end

      def allow(method, options = {})
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
        { :allow => { :if => [], :unless => [] },
          :deny  => { :if => [], :unless => [] }
        }
      end

    end

    def initialize(accessee, object)
      @accessee = accessee
      @object = object
      self
    end

    def method_missing(meth, *args, &block)
      if respond_to?(meth)
        raise "TODO!!!" if self.class.policies.nil? or self.class.policies.empty?
        if call_allowed?(meth)
          @object.send(meth, *args, &block)
        elsif call_denied?(meth)
          raise ObjectBouncer::PermissionDenied.new
        end
      else
        super
      end
    end

    def respond_to?(meth)
      @object.respond_to?(meth)
    end

    private
      def call_allowed?(meth)
        if policies = self.class.policies[meth]
          return true if !policies[:allow][:unless].empty? && !policies[:allow][:unless].detect{|policy| policy.call(@accessee, @object) rescue nil}
          return true if policies[:allow][:if].detect{|policy| policy.call(@accessee, @object) rescue nil}
          return true if policies[:deny][:unless].detect{|policy| policy.call(@accessee, @object) rescue nil}
        end
      end

      def call_denied?(meth)
        return true if self.class.lockdown?
        if policies = self.class.policies[meth]
          return true if policies[:allow][:unless].detect{|policy| policy.call(@accessee, @object) rescue nil}
          return true if policies[:deny][:if].detect{|policy| policy.call(@accessee, @object) rescue nil}
          return true if !policies[:deny][:unless].empty? && !call_allowed?(meth)
        end
      end

      def accessee=(val)
        @accessee = val
      end

      def object=(val)
        @object = val
      end

  end
end
