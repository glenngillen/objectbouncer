module ObjectBouncer
  class Error < StandardError; end
  class PermissionDenied < Error; end
  class ArgumentError < Error; end
end

