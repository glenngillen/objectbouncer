base_dir = File.join(File.dirname(__FILE__), "objectbouncer")
["base", "errors"].each do |lib|
  require File.join(base_dir, lib)
end
