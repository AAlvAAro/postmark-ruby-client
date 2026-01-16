# frozen_string_literal: true

module PostmarkClient
  module Resources
    # Email resource client for sending emails via the Postmark API.
    #
    # @example Sending a simple email
    #   emails = PostmarkClient::Resources::Emails.new
    #   response = emails.send_email(
    #     from: "sender@example.com",
    #     to: "recipient@example.com",
    #     subject: "Hello!",
    #     text_body: "Hello, World!"
    #   )
    #
    # @example Sending an email with an Email model
    #   email = PostmarkClient::Models::Email.new(
    #     from: "sender@example.com",
    #     to: "recipient@example.com",
    #     subject: "Hello!",
    #     html_body: "<h1>Hello, World!</h1>"
    #   )
    #   response = emails.send(email)
    #
    # @example Sending with a custom API token
    #   emails = PostmarkClient::Resources::Emails.new(api_token: "my-token")
    #   response = emails.send(email)
    class Emails < Client::Base
      # Send a single email
      #
      # @param email [Models::Email, Hash] the email to send
      # @return [Models::EmailResponse] the API response
      #
      # @raise [ValidationError] if the email is invalid
      # @raise [ApiError] if the API returns an error
      #
      # @example With Email model
      #   response = emails.send(email)
      #
      # @example With hash
      #   response = emails.send({
      #     from: "sender@example.com",
      #     to: "recipient@example.com",
      #     subject: "Test",
      #     text_body: "Hello"
      #   })
      def send(email)
        email = normalize_email(email)
        email.validate!

        response = post("/email", email.to_h)
        Models::EmailResponse.new(response)
      end

      # Convenience method to send an email with parameters
      #
      # @param from [String] sender email address
      # @param to [String, Array<String>] recipient email address(es)
      # @param subject [String] email subject
      # @param kwargs [Hash] additional email options
      # @option kwargs [String] :html_body HTML email body
      # @option kwargs [String] :text_body plain text email body
      # @option kwargs [String] :cc CC recipients
      # @option kwargs [String] :bcc BCC recipients
      # @option kwargs [String] :reply_to reply-to address
      # @option kwargs [String] :tag email tag
      # @option kwargs [Boolean] :track_opens whether to track opens
      # @option kwargs [String] :track_links link tracking setting
      # @option kwargs [Hash] :metadata custom metadata
      # @option kwargs [String] :message_stream message stream
      # @return [Models::EmailResponse] the API response
      #
      # @example
      #   response = emails.send_email(
      #     from: "sender@example.com",
      #     to: "recipient@example.com",
      #     subject: "Hello!",
      #     text_body: "Hello, World!",
      #     track_opens: true
      #   )
      def send_email(from:, to:, subject:, **kwargs)
        email = Models::Email.new(
          from: from,
          to: to,
          subject: subject,
          **kwargs
        )
        send(email)
      end

      # Send a batch of emails (up to 500)
      #
      # @param emails [Array<Models::Email, Hash>] array of emails to send
      # @return [Array<Models::EmailResponse>] array of API responses
      #
      # @raise [ValidationError] if any email is invalid
      # @raise [ApiError] if the API returns an error
      # @raise [ArgumentError] if batch exceeds 500 emails
      #
      # @example
      #   emails_to_send = [
      #     { from: "a@example.com", to: "b@example.com", subject: "Hi", text_body: "Hello" },
      #     { from: "a@example.com", to: "c@example.com", subject: "Hi", text_body: "Hello" }
      #   ]
      #   responses = client.send_batch(emails_to_send)
      def send_batch(emails)
        raise ArgumentError, "Batch cannot exceed 500 emails" if emails.length > 500

        normalized = emails.map { |e| normalize_email(e) }
        normalized.each(&:validate!)

        payload = normalized.map(&:to_h)
        responses = post("/email/batch", payload)

        responses.map { |r| Models::EmailResponse.new(r) }
      end

      private

      # Normalize email input to Email model
      #
      # @param email [Models::Email, Hash] the email input
      # @return [Models::Email] normalized email model
      def normalize_email(email)
        return email if email.is_a?(Models::Email)

        Models::Email.new(**symbolize_keys(email))
      end

      # Convert hash keys to symbols
      #
      # @param hash [Hash] hash with string or symbol keys
      # @return [Hash] hash with symbol keys
      def symbolize_keys(hash)
        hash.transform_keys do |key|
          case key
          when "From", :From then :from
          when "To", :To then :to
          when "Cc", :Cc then :cc
          when "Bcc", :Bcc then :bcc
          when "Subject", :Subject then :subject
          when "HtmlBody", :HtmlBody then :html_body
          when "TextBody", :TextBody then :text_body
          when "ReplyTo", :ReplyTo then :reply_to
          when "Tag", :Tag then :tag
          when "Headers", :Headers then :headers
          when "TrackOpens", :TrackOpens then :track_opens
          when "TrackLinks", :TrackLinks then :track_links
          when "Attachments", :Attachments then :attachments
          when "Metadata", :Metadata then :metadata
          when "MessageStream", :MessageStream then :message_stream
          else
            key.to_s.gsub(/([A-Z])/, '_\1').downcase.delete_prefix("_").to_sym
          end
        end
      end
    end
  end
end
