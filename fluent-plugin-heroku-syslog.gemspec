# frozen_string_literal: true

Gem::Specification.new do |gem|
  gem.name          = 'fluent-plugin-heroku-syslog'
  gem.version       = '0.1.1'
  gem.authors       = ['Kazuyuki Honda']
  gem.email         = ['hakobera@gmail.com']
  gem.description   = 'fluent plugin to drain heroku syslog'
  gem.summary       = 'fluent plugin to drain heroku syslog'
  gem.homepage      = 'https://github.com/hakobera/fluent-plugin-heroku-syslog'
  gem.license       = 'APLv2'

  gem.files         = `git ls-files`.split($ORS)
  gem.executables   = gem.files.grep(%r{^bin/}).map { |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ['lib']

  gem.add_runtime_dependency 'fluentd', '>= 1.0.0'
  gem.add_development_dependency 'rake'
  gem.add_development_dependency('test-unit', ['~> 3.1.0'])
end
