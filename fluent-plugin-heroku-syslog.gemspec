# frozen_string_literal: true

Gem::Specification.new do |gem|
  gem.name          = 'fluent-plugin-heroku-syslog-http'
  gem.version       = '0.2.1'
  gem.authors       = ['Drivy', 'Kazuyuki Honda']
  gem.email         = ['sre@drivy.com']
  gem.description   = 'fluent plugin to drain heroku syslog'
  gem.summary       = 'fluent plugin to drain heroku syslog'
  gem.homepage      = 'https://github.com/drivy/fluent-plugin-heroku-syslog-http'
  gem.license       = 'APLv2'

  gem.files         = `git ls-files`.split($ORS)
  gem.executables   = gem.files.grep(%r{^bin/}).map { |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ['lib']

  gem.add_runtime_dependency 'fluentd', '>= 1.0.0'
  gem.add_development_dependency 'rake'
  gem.add_development_dependency('test-unit', ['~> 3.1.0'])
end
