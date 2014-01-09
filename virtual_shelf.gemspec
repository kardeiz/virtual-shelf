$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "virtual_shelf/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "virtual-shelf"
  s.version     = VirtualShelf::VERSION
  s.authors     = ["Jacob Brown"]
  s.email       = ["j.h.brown@tcu.edu"]
  s.homepage    = "https://github.com/kardeiz/virtual-shelf"
  s.summary     = "A virtual shelf browse application for library catalogs"
  s.description = "A virtual shelf browse application for library catalogs"

  s.files = Dir["{app,config,db,lib}/**/*"] + ["MIT-LICENSE", "Rakefile", "README.rdoc"]
  # s.test_files = Dir["test/**/*"]

  s.add_dependency "rails", "~> 3.2.13"
  s.add_dependency "squeel"
  s.add_dependency "jquery-rails"
  s.add_dependency "fastercsv"
  s.add_dependency "twitter-bootstrap-rails", "2.2.6"
  s.add_dependency "activerecord-import"

  s.add_development_dependency "sqlite3"
  s.add_development_dependency "therubyracer"
  s.add_development_dependency "less-rails"
  s.add_development_dependency "mysql2"
  s.add_development_dependency "ruby-oci8"
  s.add_development_dependency "activerecord-oracle_enhanced-adapter"
end
