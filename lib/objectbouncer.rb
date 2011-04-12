base_dir = File.join(File.dirname(__FILE__), "objectbouncer")
["class_methods", "base", "errors"].each do |lib|
  require File.join(base_dir, lib)
end
