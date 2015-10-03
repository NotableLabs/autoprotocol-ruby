$:.unshift(File.join(File.dirname(__FILE__), 'lib'))

require 'autoprotocol/version'

spec = Gem::Specification.new do |s|
  s.name = 'autoprotocol'
  s.version = Autoprotocol::VERSION.dup
  s.summary = 'Ruby library for generating Autoprotocol'
  s.authors = ['Connor Warnock', 'Transon Nguyen']
  s.email = ['connor@notablelabs.com', 'transon@notablelabs.com']
  s.homepage = 'https://github.com/NotableLabs/autoprotocol-ruby'
  s.license = 'MIT'
  s.required_ruby_version = '>= 2.0.0'

  s.add_dependency('json', '~> 1.8.1')
  s.add_development_dependency('mocha', '~> 0.13.2')
  s.add_development_dependency('shoulda', '~> 3.4.0')
  s.add_development_dependency('test-unit')
  s.add_development_dependency('minitest-fail-fast')
  s.add_development_dependency('rake')

  s.files = `git ls-files`.split("\n")
  s.require_paths = ['lib']
end
