# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "vnews/version"

Gem::Specification.new do |s|
  s.name        = "vnews"
  s.version     = Vnews::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Daniel Choi"]
  s.email       = ["dhchoi@gmail.com"]
  s.homepage    = "http://danielchoi.com/software/vnews.html"
  s.summary     = %q{A Vim news reader}
  s.description = %q{Read your feeds in Vim}

  s.rubyforge_project = "vnews"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_dependency 'feed_yamlizer'
  s.add_dependency 'nokogiri'
end
