
lib = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "relaton_gb/version"

Gem::Specification.new do |spec|
  spec.name          = "relaton-gb"
  spec.version       = RelatonGb::VERSION
  spec.authors       = ["Ribose Inc."]
  spec.email         = ["pen.source@ribose.com"]

  spec.summary       = "RelatonGb: retrieve Chinese GB Standards for bibliographic"\
                       " use using the BibliographicItem model."
  spec.description   = "RelatonGb: retrieve Chinese GB Standards for bibliographic"\
                       " use using the BibliographicItem model."
  spec.homepage      = "https://github.com/metanorma/relaton_gb"
  spec.license       = "BSD-2-Clause"

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]
  spec.required_ruby_version = Gem::Requirement.new(">= 2.4.0")

  # spec.add_development_dependency "debase"
  spec.add_development_dependency "equivalent-xml", "~> 0.6"
  spec.add_development_dependency "pry-byebug"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  # spec.add_development_dependency "ruby-debug-ide"
  spec.add_development_dependency "ruby-jing"
  spec.add_development_dependency "simplecov"
  spec.add_development_dependency "vcr"
  spec.add_development_dependency "webmock"

  spec.add_dependency "cnccs", "~> 0.1.1"
  spec.add_dependency "gb-agencies", "~> 0.0.1"
  spec.add_dependency "relaton-iso-bib", ">= 1.8.0"
end
