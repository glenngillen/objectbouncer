Gem::Specification.new do |s|
  s.version = '0.1.1'
  s.name = "objectbouncer"
  s.files = ["README.mdown", "Rakefile"]
  s.files += Dir["lib/**/*.rb","test/**/*"]
  s.summary = "A simple object proxy to restrict access to methods and attributes"
  s.description = "A simple DSL and object proxy to restrict access to instances of your classes based on any conditional you provide"
  s.email = "glenn@rubypond.com"
  s.homepage = "http://github.com/rubypond/objectbouncer"
  s.authors = ["Glenn Gillen"]
  s.test_files = Dir["test/**/*"]
  s.require_paths = [".", "lib"]
  s.has_rdoc = 'false'

  if s.respond_to? :specification_version
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 2
  end
end
