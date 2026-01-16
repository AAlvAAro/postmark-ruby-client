# frozen_string_literal: true

require "time"

require_relative "postmark_client/version"
require_relative "postmark_client/errors"
require_relative "postmark_client/configuration"
require_relative "postmark_client/client/base"
require_relative "postmark_client/models/attachment"
require_relative "postmark_client/models/email"
require_relative "postmark_client/models/email_response"
require_relative "postmark_client/resources/emails"

# PostmarkClient is a Ruby gem for interacting with the Postmark transactional email API.
# It provides a clean, extensible interface for sending emails via Postmark.
#
# @example Basic configuration
#   PostmarkClient.configure do |config|
#     config.api_token = ENV["POSTMARK_API_TOKEN"]
#   end
#
# @example Sending an email
#   email = PostmarkClient::Models::Email.new(
#     from: "sender@example.com",
#     to: "recipient@example.com",
#     subject: "Hello!",
#     text_body: "Hello, World!"
#   )
#
#   client = PostmarkClient::Resources::Emails.new
#   response = client.send(email)
#   puts response.message_id if response.success?
#
# @example Using the convenience method
#   client = PostmarkClient::Resources::Emails.new
#   response = client.send_email(
#     from: "sender@example.com",
#     to: "recipient@example.com",
#     subject: "Hello!",
#     text_body: "Hello, World!"
#   )
#
# @see https://postmarkapp.com/developer Postmark API Documentation
module PostmarkClient
  class << self
    # Convenience method to create an Emails client
    #
    # @param api_token [String, nil] optional API token override
    # @return [Resources::Emails] an Emails client instance
    #
    # @example
    #   response = PostmarkClient.emails.send_email(
    #     from: "sender@example.com",
    #     to: "recipient@example.com",
    #     subject: "Hello!",
    #     text_body: "Hello, World!"
    #   )
    def emails(api_token: nil)
      Resources::Emails.new(api_token: api_token)
    end

    # Send an email using the default configuration
    #
    # @param email [Models::Email, Hash] the email to send
    # @return [Models::EmailResponse] the API response
    #
    # @example
    #   PostmarkClient.deliver(
    #     from: "sender@example.com",
    #     to: "recipient@example.com",
    #     subject: "Hello!",
    #     text_body: "Hello, World!"
    #   )
    def deliver(email)
      emails.send(email.is_a?(Hash) ? Models::Email.new(**email) : email)
    end
  end
end
