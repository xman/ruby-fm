lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'fm/version'


Gem::Specification.new do |spec|
    spec.name          = 'fm'
    spec.version       = FM::VERSION
    spec.summary       = %q{Compute and record file checksum. Verify file content integrity using checksum. Identify duplicated files or backup locations.}
    spec.description   = %q{Manage files scattered over multiple physical storages. Using file checksum, it's possible to verify content integrity of your backups, look up locations of the backups at various storages.}

    spec.authors       = ['ShinYee']
    spec.email         = ['shinyee@speedgocomputing.com']
    spec.homepage      = 'http://github.com/xman/ruby-fm'
    spec.licenses      = ['MIT']

    spec.files         = `git ls-files`.split($/)
    spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
    spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
    spec.require_paths = ["lib"]

    spec.required_ruby_version = '>= 2.0.0'

    spec.add_development_dependency "bundler", "~> 1.9"
    spec.add_development_dependency "rake", "~> 10.1"
end
