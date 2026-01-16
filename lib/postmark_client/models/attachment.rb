# frozen_string_literal: true

require "base64"

module PostmarkClient
  # Represents an email attachment for the Postmark API.
  #
  # @example Creating a simple attachment
  #   attachment = PostmarkClient::Attachment.new(
  #     name: "document.pdf",
  #     content: File.read("document.pdf"),
  #     content_type: "application/pdf"
  #   )
  #
  # @example Creating an inline image attachment
  #   attachment = PostmarkClient::Attachment.new(
  #     name: "logo.png",
  #     content: File.read("logo.png"),
  #     content_type: "image/png",
  #     content_id: "cid:logo.png"
  #   )
  #
  # @example Creating from a file path
  #   attachment = PostmarkClient::Attachment.from_file("path/to/file.pdf")
  class Attachment
    # @return [String] the filename of the attachment
    attr_accessor :name

    # @return [String] the Base64-encoded content of the attachment
    attr_accessor :content

    # @return [String] the MIME type of the attachment
    attr_accessor :content_type

    # @return [String, nil] the content ID for inline attachments
    attr_accessor :content_id

    # Initialize a new attachment
    #
    # @param name [String] the filename
    # @param content [String] the file content (will be Base64 encoded if not already)
    # @param content_type [String] the MIME type
    # @param content_id [String, nil] optional content ID for inline images
    # @param base64_encoded [Boolean] whether content is already Base64 encoded
    def initialize(name:, content:, content_type:, content_id: nil, base64_encoded: false)
      @name = name
      @content = base64_encoded ? content : Base64.strict_encode64(content)
      @content_type = content_type
      @content_id = content_id
    end

    # Create an attachment from a file path
    #
    # @param file_path [String] path to the file
    # @param content_type [String, nil] optional MIME type (auto-detected if not provided)
    # @param content_id [String, nil] optional content ID for inline images
    # @return [Attachment] a new attachment instance
    def self.from_file(file_path, content_type: nil, content_id: nil)
      name = File.basename(file_path)
      content = File.binread(file_path)
      detected_content_type = content_type || detect_content_type(name)

      new(
        name: name,
        content: content,
        content_type: detected_content_type,
        content_id: content_id
      )
    end

    # Convert the attachment to a hash for API requests
    #
    # @return [Hash] the attachment as a hash
    def to_h
      hash = {
        "Name" => name,
        "Content" => content,
        "ContentType" => content_type
      }
      hash["ContentID"] = content_id if content_id
      hash
    end

    # Check if this is an inline attachment
    #
    # @return [Boolean] true if this is an inline attachment
    def inline?
      !content_id.nil?
    end

    private

    # Detect content type from file extension
    #
    # @param filename [String] the filename
    # @return [String] the detected MIME type
    def self.detect_content_type(filename)
      extension = File.extname(filename).downcase.delete(".")

      CONTENT_TYPES.fetch(extension, "application/octet-stream")
    end

    # Common content types by file extension
    CONTENT_TYPES = {
      "pdf" => "application/pdf",
      "doc" => "application/msword",
      "docx" => "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
      "xls" => "application/vnd.ms-excel",
      "xlsx" => "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
      "png" => "image/png",
      "jpg" => "image/jpeg",
      "jpeg" => "image/jpeg",
      "gif" => "image/gif",
      "svg" => "image/svg+xml",
      "txt" => "text/plain",
      "html" => "text/html",
      "htm" => "text/html",
      "css" => "text/css",
      "js" => "application/javascript",
      "json" => "application/json",
      "xml" => "application/xml",
      "zip" => "application/zip",
      "csv" => "text/csv"
    }.freeze
  end
end
