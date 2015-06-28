lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'fm/version'


Gem::Specification.new do |spec|
    spec.name           = 'fm'
    spec.version        = FM::VERSION
    spec.summary        = %q{Managing files over multiple storage resources.}
    spec.description    = %q{FM indexes folders, searches for duplicated files, replicates files for backup.}

    spec.authors            = ['ShinYee']
    spec.email              = ['shinyee@speedgocomputing.com']
    spec.homepage           = 'http://github.com/xman/ruby-fm'
    spec.licenses           = ['MIT']

    spec.required_ruby_version      = '>= 2.0.0'

    spec.files         = `git ls-files`.split($/)
    spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
    spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
    spec.require_paths = ["lib"]

    spec.add_development_dependency "bundler", "~> 1.9"
    spec.add_development_dependency "rake", "~> 10.1"
end
