Gem::Specification.new do |s|
  s.version = '0.0.1'
  s.name = "objectbouncer"
  s.files = ["README.mdown", "Rakefile"]
  s.files += Dir["lib/**/*.rb","test/**/*"]
  s.summary = ""
  s.description = ""
  s.email = "glenn@rubypond.com"
  s.homepage = "http://github.com/rubypond/objectbouncer"
  s.authors = ["Glenn Gillen"]
  s.test_files = Dir["test/**/*"]
  s.require_paths = [".", "lib"]
  s.has_rdoc = 'false'

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 2

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency('httparty', '= 0.6.1')
    else
      s.add_dependency('httparty', '= 0.6.1')
    end
  else
    s.add_dependency('httparty', '= 0.6.1')
  end
end
