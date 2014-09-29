# encoding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'timezone_parser/version'

Gem::Specification.new do |spec|
  spec.name          = 'TimezoneParser'
  spec.version       = TimezoneParser::VERSION
  spec.authors       = ['Dāvis']
  spec.email         = ['davispuh@gmail.com']
  spec.description   = 'Library for parsing Timezone names and abbrevations to corresponding UTC offsets and much more'
  spec.summary       = 'Parse Timezone names written in any language to offsets and TimeZone identifiers'
  spec.homepage      = 'https://github.com/davispuh/TimezoneParser'
  spec.license       = 'UNLICENSE'

  spec.files         = `git ls-files`.split($/)
  spec.files.delete_if { |name| name[-4, 4] == '.yml' }
  spec.files         << 'data/version.yml'
  ['abbreviations.dat', 'countries.dat', 'metazones.dat',
  'rails.dat', 'rails_i18n.dat', 'timezones.dat',
  'windows_offsets.dat', 'windows_timezones.dat', 'windows_zonenames.dat'].each do |name|
    spec.files       << 'data/' + name
  end

  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_runtime_dependency 'tzinfo'
  spec.add_runtime_dependency 'insensitive_hash'

  spec.add_development_dependency 'bundler', '>= 1.3'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rspec'
  spec.add_development_dependency 'simplecov'
  spec.add_development_dependency 'yard'
  spec.add_development_dependency 'tzinfo-data'
  spec.add_development_dependency 'ruby-cldr'
  spec.add_development_dependency 'activesupport'
  spec.add_development_dependency 'rubyzip'
end
