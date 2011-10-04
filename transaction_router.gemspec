# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "transaction_router/version"

Gem::Specification.new do |spec|
  spec.name        = "transaction_router"
  spec.version     = TransactionRouter::VERSION
  spec.authors     = ["Pablo Marambio"]
  spec.email       = ["pablo.marambio@multicaja.cl"]
  spec.homepage    = ""
  spec.summary     = %q{Gem summary}
  spec.description = %q{Gem description}

  spec.rubyforge_project = "transaction_router"

  spec.files         = `git ls-files`.split("\n")
  spec.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  spec.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  spec.require_paths = ["lib"]

end
