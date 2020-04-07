# frozen_string_literal: true

require_relative 'lib/delayed_job_metrics/version'

Gem::Specification.new do |spec|
  spec.name          = 'delayed_job_metrics'
  spec.version       = DelayedJobMetrics::VERSION
  spec.authors       = ['Al-waleed Shihadeh']
  spec.email         = ['wshihadeh dot dev at gmail dot com']

  spec.summary       = 'Delayed Job Promtheues Metrcis'
  spec.description   = 'Delayed Job Promtheues Metrcis'
  spec.homepage      = 'https://github.com/wshihadeh/delayed_job_metrics'
  spec.license       = 'MIT'
  spec.required_ruby_version = Gem::Requirement.new('>= 2.3.0')

  spec.metadata['homepage_uri'] = spec.homepage

  # Specify which files should be added to the gem when it is released.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject do |f|
      f.match(%r{^(test|spec|features)/})
    end
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'prometheus-client'

  spec.add_development_dependency 'rake', '~> 12.0'
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'rubocop'
end
