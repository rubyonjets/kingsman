# frozen_string_literal: true

require_relative "lib/kingsman/version"

Gem::Specification.new do |spec|
  spec.name = "kingsman"
  spec.version = Kingsman::VERSION
  spec.authors = ["Tung Nguyen"]
  spec.email = ["tongueroo@gmail.com"]

  spec.summary = "Kingsman"
  spec.homepage = "https://github.com/boltops-tools/kingsman"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 2.6.0"

  spec.metadata["homepage_uri"] = spec.homepage

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (File.expand_path(f) == __FILE__) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git .circleci appveyor Gemfile])
    end
  end
  spec.require_paths = ["lib"]

  # Uncomment to register a new dependency of your gem
  # spec.add_dependency "example-gem", "~> 1.0"
end
