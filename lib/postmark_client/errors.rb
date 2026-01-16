# frozen_string_literal: true

module PostmarkClient
  # Base error class for all PostmarkClient errors
  class Error < StandardError; end

  # Raised when configuration is invalid or missing
  #
  # @example
  #   raise ConfigurationError, "API token is required"
  class ConfigurationError < Error; end

  # Raised when there are network connectivity issues
  #
  # @example
  #   raise ConnectionError, "Connection timeout"
  class ConnectionError < Error; end

  # Raised when the Postmark API returns an error response
  #
  # @example Handling API errors
  #   begin
  #     client.send_email(email)
  #   rescue PostmarkClient::ApiError => e
  #     puts "Error #{e.error_code}: #{e.message}"
  #     puts "Response: #{e.response}"
  #   end
  class ApiError < Error
    # @return [Integer, String, nil] the Postmark error code
    attr_reader :error_code

    # @return [Hash, nil] the full error response body
    attr_reader :response

    # Initialize a new API error
    #
    # @param message [String] the error message
    # @param error_code [Integer, String, nil] the Postmark error code
    # @param response [Hash, nil] the full response body
    def initialize(message, error_code: nil, response: nil)
      @error_code = error_code
      @response = response
      super(message)
    end
  end

  # Raised when email validation fails before sending
  #
  # @example
  #   raise ValidationError, "From address is required"
  class ValidationError < Error; end
end
