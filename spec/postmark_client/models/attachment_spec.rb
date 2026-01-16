# frozen_string_literal: true

require "base64"

RSpec.describe PostmarkClient::Attachment do
  describe "#initialize" do
    it "creates an attachment with basic attributes" do
      attachment = described_class.new(
        name: "test.txt",
        content: "Hello, World!",
        content_type: "text/plain"
      )

      expect(attachment.name).to eq("test.txt")
      expect(attachment.content_type).to eq("text/plain")
    end

    it "Base64 encodes content by default" do
      attachment = described_class.new(
        name: "test.txt",
        content: "Hello",
        content_type: "text/plain"
      )

      expect(attachment.content).to eq(Base64.strict_encode64("Hello"))
    end

    it "skips encoding when base64_encoded is true" do
      already_encoded = Base64.strict_encode64("Hello")

      attachment = described_class.new(
        name: "test.txt",
        content: already_encoded,
        content_type: "text/plain",
        base64_encoded: true
      )

      expect(attachment.content).to eq(already_encoded)
    end

    it "accepts content_id for inline attachments" do
      attachment = described_class.new(
        name: "logo.png",
        content: "image-data",
        content_type: "image/png",
        content_id: "cid:logo.png"
      )

      expect(attachment.content_id).to eq("cid:logo.png")
    end
  end

  describe ".from_file" do
    let(:temp_file) do
      file = Tempfile.new(["test", ".txt"])
      file.write("File content")
      file.close
      file
    end

    after do
      temp_file.unlink
    end

    it "creates an attachment from a file path" do
      attachment = described_class.from_file(temp_file.path)

      expect(attachment.name).to eq(File.basename(temp_file.path))
      expect(attachment.content).to eq(Base64.strict_encode64("File content"))
    end

    it "auto-detects content type from extension" do
      pdf_file = Tempfile.new(["doc", ".pdf"])
      pdf_file.write("PDF content")
      pdf_file.close

      begin
        attachment = described_class.from_file(pdf_file.path)
        expect(attachment.content_type).to eq("application/pdf")
      ensure
        pdf_file.unlink
      end
    end

    it "uses provided content_type over auto-detection" do
      attachment = described_class.from_file(temp_file.path, content_type: "application/octet-stream")

      expect(attachment.content_type).to eq("application/octet-stream")
    end

    it "accepts content_id parameter" do
      attachment = described_class.from_file(temp_file.path, content_id: "cid:test")

      expect(attachment.content_id).to eq("cid:test")
    end

    it "defaults to application/octet-stream for unknown extensions" do
      unknown_file = Tempfile.new(["file", ".xyz123"])
      unknown_file.write("content")
      unknown_file.close

      begin
        attachment = described_class.from_file(unknown_file.path)
        expect(attachment.content_type).to eq("application/octet-stream")
      ensure
        unknown_file.unlink
      end
    end
  end

  describe "#to_h" do
    it "converts to API format hash" do
      attachment = described_class.new(
        name: "test.txt",
        content: "Hello",
        content_type: "text/plain"
      )

      hash = attachment.to_h

      expect(hash["Name"]).to eq("test.txt")
      expect(hash["Content"]).to eq(Base64.strict_encode64("Hello"))
      expect(hash["ContentType"]).to eq("text/plain")
    end

    it "includes ContentID when present" do
      attachment = described_class.new(
        name: "logo.png",
        content: "data",
        content_type: "image/png",
        content_id: "cid:logo.png"
      )

      hash = attachment.to_h

      expect(hash["ContentID"]).to eq("cid:logo.png")
    end

    it "excludes ContentID when nil" do
      attachment = described_class.new(
        name: "test.txt",
        content: "data",
        content_type: "text/plain"
      )

      expect(attachment.to_h).not_to have_key("ContentID")
    end
  end

  describe "#inline?" do
    it "returns true when content_id is present" do
      attachment = described_class.new(
        name: "logo.png",
        content: "data",
        content_type: "image/png",
        content_id: "cid:logo.png"
      )

      expect(attachment.inline?).to be(true)
    end

    it "returns false when content_id is nil" do
      attachment = described_class.new(
        name: "doc.pdf",
        content: "data",
        content_type: "application/pdf"
      )

      expect(attachment.inline?).to be(false)
    end
  end

  describe "content type detection" do
    it "detects common image types" do
      { "png" => "image/png", "jpg" => "image/jpeg", "jpeg" => "image/jpeg", "gif" => "image/gif" }.each do |ext, type|
        file = Tempfile.new(["img", ".#{ext}"])
        file.write("data")
        file.close

        begin
          attachment = described_class.from_file(file.path)
          expect(attachment.content_type).to eq(type), "Expected .#{ext} to be #{type}"
        ensure
          file.unlink
        end
      end
    end

    it "detects document types" do
      { "pdf" => "application/pdf", "doc" => "application/msword", "txt" => "text/plain" }.each do |ext, type|
        file = Tempfile.new(["doc", ".#{ext}"])
        file.write("data")
        file.close

        begin
          attachment = described_class.from_file(file.path)
          expect(attachment.content_type).to eq(type), "Expected .#{ext} to be #{type}"
        ensure
          file.unlink
        end
      end
    end
  end
end
