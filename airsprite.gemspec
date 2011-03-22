$:.push File.expand_path("../lib", __FILE__)
require "airsprite/version"

Gem::Specification.new do |s|
  s.name        = "airsprite"
  s.version     = Airsprite::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["John 'asceth' Long"]
  s.email       = ["machinist@asceth.com"]
  s.homepage    = "http://github.com/asceth/airsprite"
  s.summary     = "AirPlay SDK Sprite Sheet generator"
  s.description = "A gem for creating sprite sheets for the AirPlay SDK"

  s.rubyforge_project = "bbcoder"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_dependency 'rmagick'

  s.add_development_dependency 'rspec'
  s.add_development_dependency 'rr'
end

