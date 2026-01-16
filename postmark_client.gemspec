# frozen_string_literal: true

require_relative "lib/postmark_client/version"

Gem::Specification.new do |spec|
  spec.name = "postmark_ruby_client"
  spec.version = PostmarkClient::VERSION
  spec.authors = ["Alvaro Delgado"]
  spec.email = ["hola@alvarodelgado.dev"]

  spec.summary = "A Ruby gem for interacting with the Postmark API"
  spec.description = "A clean, extensible Ruby client for the Postmark transactional email API. " \
                     "Built with Faraday and designed for Rails 8+ applications."
  spec.homepage = "https://github.com/AAlvAAro/postmark_ruby_client"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2.0"

  spec.metadata["allowed_push_host"] = "https://rubygems.org"
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/CHANGELOG.md"
  spec.metadata["rubygems_mfa_required"] = "true"

  # Specify which files should be added to the gem when it is released.
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git .github appveyor Gemfile])
    end
  rescue Errno::ENOENT
    Dir.glob("**/*").reject { |f| File.directory?(f) }
  end

  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Runtime dependencies
  spec.add_dependency "base64", "~> 0.1"
  spec.add_dependency "faraday", ">= 2.0", "< 3.0"
  spec.add_dependency "faraday-multipart", "~> 1.0"

  # Development dependencies
  spec.add_development_dependency "bundler", "~> 2.0"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rspec", "~> 3.12"
  spec.add_development_dependency "webmock", "~> 3.19"
  spec.add_development_dependency "yard", "~> 0.9"
  spec.add_development_dependency "simplecov", "~> 0.22"
end
