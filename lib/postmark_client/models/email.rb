# frozen_string_literal: true

module PostmarkClient
  # Represents an email message for the Postmark API.
  # Provides a clean Ruby interface for building email payloads.
  #
  # @example Creating a simple email
  #   email = PostmarkClient::Email.new(
  #     from: "sender@example.com",
  #     to: "recipient@example.com",
  #     subject: "Hello!",
  #     text_body: "Hello, World!"
  #   )
  #
  # @example Creating an email with HTML and attachments
  #   email = PostmarkClient::Email.new(
  #     from: "John Doe <john@example.com>",
  #     to: ["alice@example.com", "bob@example.com"],
  #     cc: "manager@example.com",
  #     subject: "Monthly Report",
  #     html_body: "<h1>Report</h1><p>See attached.</p>",
  #     text_body: "Report - See attached.",
  #     track_opens: true
  #   )
  #   email.add_attachment(name: "report.pdf", content: pdf_data, content_type: "application/pdf")
  #
  # @example Using the builder pattern
  #   email = PostmarkClient::Email.new
  #     .from("sender@example.com")
  #     .to("recipient@example.com")
  #     .subject("Hello")
  #     .text_body("Hello, World!")
  class Email
    # @return [String] sender email address
    attr_accessor :from

    # @return [String, Array<String>] recipient email address(es)
    attr_accessor :to

    # @return [String, Array<String>, nil] CC recipient email address(es)
    attr_accessor :cc

    # @return [String, Array<String>, nil] BCC recipient email address(es)
    attr_accessor :bcc

    # @return [String] email subject
    attr_accessor :subject

    # @return [String, nil] HTML email body
    attr_accessor :html_body

    # @return [String, nil] plain text email body
    attr_accessor :text_body

    # @return [String, nil] reply-to email address
    attr_accessor :reply_to

    # @return [String, nil] email tag for categorization
    attr_accessor :tag

    # @return [Array<Hash>] custom email headers
    attr_accessor :headers

    # @return [Boolean] whether to track email opens
    attr_accessor :track_opens

    # @return [String] link tracking setting ("None", "HtmlAndText", "HtmlOnly", "TextOnly")
    attr_accessor :track_links

    # @return [Array<Attachment>] email attachments
    attr_accessor :attachments

    # @return [Hash] custom metadata key-value pairs
    attr_accessor :metadata

    # @return [String] message stream identifier
    attr_accessor :message_stream

    # Valid link tracking options
    TRACK_LINKS_OPTIONS = %w[None HtmlAndText HtmlOnly TextOnly].freeze

    # Initialize a new email
    #
    # @param from [String, nil] sender email address
    # @param to [String, Array<String>, nil] recipient email address(es)
    # @param cc [String, Array<String>, nil] CC recipient(s)
    # @param bcc [String, Array<String>, nil] BCC recipient(s)
    # @param subject [String, nil] email subject
    # @param html_body [String, nil] HTML body
    # @param text_body [String, nil] plain text body
    # @param reply_to [String, nil] reply-to address
    # @param tag [String, nil] email tag
    # @param headers [Array<Hash>, nil] custom headers
    # @param track_opens [Boolean, nil] track opens
    # @param track_links [String, nil] link tracking setting
    # @param attachments [Array<Attachment>, nil] attachments
    # @param metadata [Hash, nil] custom metadata
    # @param message_stream [String, nil] message stream
    def initialize(
      from: nil,
      to: nil,
      cc: nil,
      bcc: nil,
      subject: nil,
      html_body: nil,
      text_body: nil,
      reply_to: nil,
      tag: nil,
      headers: nil,
      track_opens: nil,
      track_links: nil,
      attachments: nil,
      metadata: nil,
      message_stream: nil
    )
      @from = from
      @to = to
      @cc = cc
      @bcc = bcc
      @subject = subject
      @html_body = html_body
      @text_body = text_body
      @reply_to = reply_to
      @tag = tag
      @headers = headers || []
      @track_opens = track_opens
      @track_links = track_links
      @attachments = attachments || []
      @metadata = metadata || {}
      @message_stream = message_stream || PostmarkClient.configuration.default_message_stream
    end

    # Add a custom header to the email
    #
    # @param name [String] header name
    # @param value [String] header value
    # @return [self] returns self for method chaining
    def add_header(name:, value:)
      @headers << { "Name" => name, "Value" => value }
      self
    end

    # Add an attachment to the email
    #
    # @param attachment [Attachment] an Attachment instance
    # @return [self] returns self for method chaining
    #
    # @overload add_attachment(attachment)
    #   @param attachment [Attachment] an Attachment instance
    #
    # @overload add_attachment(name:, content:, content_type:, content_id: nil)
    #   @param name [String] filename
    #   @param content [String] file content
    #   @param content_type [String] MIME type
    #   @param content_id [String, nil] content ID for inline attachments
    def add_attachment(attachment = nil, **kwargs)
      if attachment.is_a?(Attachment)
        @attachments << attachment
      elsif kwargs.any?
        @attachments << Attachment.new(**kwargs)
      else
        raise ArgumentError, "Must provide an Attachment instance or attachment parameters"
      end
      self
    end

    # Add a file as an attachment
    #
    # @param file_path [String] path to the file
    # @param content_type [String, nil] optional MIME type
    # @param content_id [String, nil] optional content ID
    # @return [self] returns self for method chaining
    def attach_file(file_path, content_type: nil, content_id: nil)
      @attachments << Attachment.from_file(file_path, content_type: content_type, content_id: content_id)
      self
    end

    # Add metadata to the email
    #
    # @param key [String, Symbol] metadata key
    # @param value [String] metadata value
    # @return [self] returns self for method chaining
    def add_metadata(key, value)
      @metadata[key.to_s] = value
      self
    end

    # Validate the email before sending
    #
    # @return [Boolean] true if valid
    # @raise [ValidationError] if validation fails
    def validate!
      raise ValidationError, "From address is required" if from.nil? || from.empty?
      raise ValidationError, "To address is required" if to.nil? || (to.is_a?(Array) && to.empty?) || (to.is_a?(String) && to.empty?)
      raise ValidationError, "Either HtmlBody or TextBody is required" if (html_body.nil? || html_body.empty?) && (text_body.nil? || text_body.empty?)

      if track_links && !TRACK_LINKS_OPTIONS.include?(track_links)
        raise ValidationError, "TrackLinks must be one of: #{TRACK_LINKS_OPTIONS.join(', ')}"
      end

      true
    end

    # Check if the email is valid
    #
    # @return [Boolean] true if valid, false otherwise
    def valid?
      validate!
      true
    rescue ValidationError
      false
    end

    # Convert the email to a hash for API requests
    #
    # @return [Hash] the email as a hash matching Postmark API format
    def to_h
      hash = {}

      hash["From"] = from if from
      hash["To"] = normalize_recipients(to) if to
      hash["Cc"] = normalize_recipients(cc) if cc
      hash["Bcc"] = normalize_recipients(bcc) if bcc
      hash["Subject"] = subject if subject
      hash["HtmlBody"] = html_body if html_body
      hash["TextBody"] = text_body if text_body
      hash["ReplyTo"] = reply_to if reply_to
      hash["Tag"] = tag if tag
      hash["Headers"] = headers if headers.any?
      hash["TrackOpens"] = track_opens unless track_opens.nil?
      hash["TrackLinks"] = track_links if track_links
      hash["Attachments"] = attachments.map(&:to_h) if attachments.any?
      hash["Metadata"] = metadata if metadata.any?
      hash["MessageStream"] = message_stream if message_stream

      hash
    end

    # Alias for to_h
    alias_method :to_api_hash, :to_h

    private

    # Normalize recipients to comma-separated string
    #
    # @param recipients [String, Array<String>] recipient(s)
    # @return [String] comma-separated recipients
    def normalize_recipients(recipients)
      return recipients if recipients.is_a?(String)

      recipients.join(", ")
    end
  end
end
