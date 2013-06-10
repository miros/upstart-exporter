# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "upstart-exporter/version"

Gem::Specification.new do |s|
  s.name        = "upstart-exporter"
  s.version     = Upstart::Exporter::VERSION
  s.authors     = ["Ilya Averyanov"]
  s.email       = ["ilya@averyanov.org"]
  s.homepage    = ""
  s.summary     = %q{Gem for converting Procfile-like files to upstart scripts}
  s.description = %q{Gem for converting Procfile-like files to upstart scripts}

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end
