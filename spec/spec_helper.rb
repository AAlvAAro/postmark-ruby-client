# frozen_string_literal: true

require "simplecov"
SimpleCov.start do
  add_filter "/spec/"
  enable_coverage :branch
end

require "postmark_client"
require "webmock/rspec"
require "tempfile"

# Disable all external HTTP connections during tests
WebMock.disable_net_connect!(allow_localhost: true)

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  # Reset configuration before each test
  config.before do
    PostmarkClient.reset_configuration!
  end

  # Allow setting test API token
  config.before do
    PostmarkClient.configure do |c|
      c.api_token = "test-api-token"
    end
  end
end

# Helper module for test utilities
module TestHelpers
  # Build a stub URL for Postmark API
  def stub_postmark_url(path)
    "https://api.postmarkapp.com#{path}"
  end

  # Create a successful email response
  def successful_email_response(to: "recipient@example.com")
    {
      "To" => to,
      "SubmittedAt" => "2024-01-15T10:30:00.0000000-05:00",
      "MessageID" => "abc123-def456-ghi789",
      "ErrorCode" => 0,
      "Message" => "OK"
    }
  end

  # Create an error email response
  def error_email_response(code:, message:)
    {
      "ErrorCode" => code,
      "Message" => message
    }
  end
end

RSpec.configure do |config|
  config.include TestHelpers
end
