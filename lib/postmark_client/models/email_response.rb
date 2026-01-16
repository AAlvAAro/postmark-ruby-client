# frozen_string_literal: true

module PostmarkClient
  # Represents a response from the Postmark Email API.
  # Wraps the API response in a convenient Ruby object.
  #
  # @example Handling a successful response
  #   response = client.send_email(email)
  #   puts "Message ID: #{response.message_id}"
  #   puts "Submitted at: #{response.submitted_at}"
  #
  # @example Checking for errors
  #   if response.success?
  #     puts "Email sent successfully!"
  #   else
  #     puts "Error: #{response.message}"
  #   end
  class EmailResponse
    # @return [String] recipient email address
    attr_reader :to

    # @return [Time] timestamp when the email was submitted
    attr_reader :submitted_at

    # @return [String] unique message identifier
    attr_reader :message_id

    # @return [Integer] error code (0 means success)
    attr_reader :error_code

    # @return [String] response message
    attr_reader :message

    # @return [Hash] raw response data
    attr_reader :raw_response

    # Initialize from API response hash
    #
    # @param response [Hash] the API response
    def initialize(response)
      @raw_response = response
      @to = response["To"]
      @submitted_at = parse_timestamp(response["SubmittedAt"])
      @message_id = response["MessageID"]
      @error_code = response["ErrorCode"]
      @message = response["Message"]
    end

    # Check if the email was sent successfully
    #
    # @return [Boolean] true if error_code is 0
    def success?
      error_code == 0
    end

    # Check if there was an error
    #
    # @return [Boolean] true if error_code is not 0
    def error?
      !success?
    end

    # Get a string representation of the response
    #
    # @return [String] human-readable response summary
    def to_s
      if success?
        "Email sent to #{to} (Message ID: #{message_id})"
      else
        "Error #{error_code}: #{message}"
      end
    end

    private

    # Parse ISO 8601 timestamp string to Time object
    #
    # @param timestamp [String, nil] the timestamp string
    # @return [Time, nil] parsed Time object
    def parse_timestamp(timestamp)
      return nil if timestamp.nil?

      Time.parse(timestamp)
    rescue ArgumentError
      nil
    end
  end
end
