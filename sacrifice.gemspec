# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'sacrifice/version'

Gem::Specification.new do |spec|
  spec.name          = 'sacrifice'
  spec.version       = Sacrifice::VERSION
  spec.authors       = ['Akira Higuchi']
  spec.email         = ['qazsewsxcd@gmail.com']

  spec.summary       = %q{Sacrifice}
  spec.description   = %q{Sacrifice}
  spec.homepage      = 'https://github.com/toiroakr/sacrifice'
  spec.license       = 'MIT'

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = 'https://rubygems.org'
  else
    raise 'RubyGems 2.0 or newer is required to protect against public gem pushes.'
  end

  spec.add_development_dependency 'bundler', '~> 1.12.a'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_dependency 'thor'
  spec.add_dependency 'facebook_test_users'
  spec.add_dependency 'open5'
  spec.add_dependency 'curb'
  spec.add_dependency 'multi_json'
  spec.add_dependency 'heredoc_unindent'
  spec.add_dependency 'rest-client'
end
