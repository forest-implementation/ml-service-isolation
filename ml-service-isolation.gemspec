# frozen_string_literal: true

require_relative "lib/ml/service/isolation/version"

Gem::Specification.new do |spec|
  spec.name = "ml-service-isolation"
  spec.version = Ml::Service::Isolation::VERSION
  spec.authors = ["Adam Ulrich", "Jan Krňávek"]
  spec.email = %w[a_ulrich@utb.cz krnavek@utb.cz]

  spec.summary = "Service enabling Novelty and Outlier anomaly detection for ml_forest."
  spec.description = "Set of services that work on ml-forest ruby gem (https://github.com/forest-implementation/ml-forest) as a part of forest-implementation project. It contains outlier service for outlier detection and novelty service for novelty detection (to detect whether new observation is novelty or not)."
  spec.homepage = "https://github.com/forest-implementation/ml-service-isolation."
  spec.required_ruby_version = ">= 2.6.0"
  #
  # spec.metadata["allowed_push_host"] = "TODO: Set to your gem server 'https://example.com'"
  #
  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/forest-implementation/ml-service-isolation"
  # spec.metadata["changelog_uri"] = "TODO: Put your gem's CHANGELOG.md URL here."

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (File.expand_path(f) == __FILE__) || f.start_with?(*%w[bin/ test/ spec/ features/ .git .circleci appveyor])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Uncomment to register a new dependency of your gem
  # spec.add_dependency "example-gem", "~> 1.0"

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end
