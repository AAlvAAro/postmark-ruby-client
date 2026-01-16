# frozen_string_literal: true

RSpec.describe PostmarkClient::Models::Email do
  describe "#initialize" do
    it "creates an email with basic attributes" do
      email = described_class.new(
        from: "sender@example.com",
        to: "recipient@example.com",
        subject: "Test",
        text_body: "Hello"
      )

      expect(email.from).to eq("sender@example.com")
      expect(email.to).to eq("recipient@example.com")
      expect(email.subject).to eq("Test")
      expect(email.text_body).to eq("Hello")
    end

    it "creates an email with all attributes" do
      email = described_class.new(
        from: "sender@example.com",
        to: ["a@example.com", "b@example.com"],
        cc: "cc@example.com",
        bcc: "bcc@example.com",
        subject: "Test",
        html_body: "<p>Hello</p>",
        text_body: "Hello",
        reply_to: "reply@example.com",
        tag: "test-tag",
        track_opens: true,
        track_links: "HtmlAndText",
        metadata: { "key" => "value" },
        message_stream: "custom-stream"
      )

      expect(email.cc).to eq("cc@example.com")
      expect(email.bcc).to eq("bcc@example.com")
      expect(email.html_body).to eq("<p>Hello</p>")
      expect(email.reply_to).to eq("reply@example.com")
      expect(email.tag).to eq("test-tag")
      expect(email.track_opens).to be(true)
      expect(email.track_links).to eq("HtmlAndText")
      expect(email.metadata).to eq("key" => "value")
      expect(email.message_stream).to eq("custom-stream")
    end

    it "uses default message stream from configuration" do
      PostmarkClient.configure { |c| c.default_message_stream = "transactional" }

      email = described_class.new(from: "a@b.com", to: "c@d.com", text_body: "hi")
      expect(email.message_stream).to eq("transactional")
    end
  end

  describe "#add_header" do
    it "adds a custom header" do
      email = described_class.new
      email.add_header(name: "X-Custom", value: "custom-value")

      expect(email.headers).to include("Name" => "X-Custom", "Value" => "custom-value")
    end

    it "returns self for method chaining" do
      email = described_class.new
      result = email.add_header(name: "X-Test", value: "test")

      expect(result).to be(email)
    end
  end

  describe "#add_attachment" do
    it "adds an Attachment instance" do
      attachment = PostmarkClient::Models::Attachment.new(
        name: "test.txt",
        content: "test content",
        content_type: "text/plain"
      )

      email = described_class.new
      email.add_attachment(attachment)

      expect(email.attachments).to include(attachment)
    end

    it "creates an attachment from parameters" do
      email = described_class.new
      email.add_attachment(
        name: "test.txt",
        content: "test content",
        content_type: "text/plain"
      )

      expect(email.attachments.first.name).to eq("test.txt")
    end

    it "raises ArgumentError without valid input" do
      email = described_class.new

      expect { email.add_attachment }.to raise_error(ArgumentError)
    end

    it "returns self for method chaining" do
      email = described_class.new
      result = email.add_attachment(name: "t.txt", content: "c", content_type: "text/plain")

      expect(result).to be(email)
    end
  end

  describe "#add_metadata" do
    it "adds metadata key-value pair" do
      email = described_class.new
      email.add_metadata("color", "blue")

      expect(email.metadata).to eq("color" => "blue")
    end

    it "accepts symbol keys" do
      email = described_class.new
      email.add_metadata(:client_id, "123")

      expect(email.metadata).to eq("client_id" => "123")
    end

    it "returns self for method chaining" do
      email = described_class.new
      result = email.add_metadata("key", "value")

      expect(result).to be(email)
    end
  end

  describe "#validate!" do
    it "returns true for valid email" do
      email = described_class.new(
        from: "sender@example.com",
        to: "recipient@example.com",
        text_body: "Hello"
      )

      expect(email.validate!).to be(true)
    end

    it "raises ValidationError when from is missing" do
      email = described_class.new(to: "a@b.com", text_body: "hi")

      expect { email.validate! }.to raise_error(
        PostmarkClient::ValidationError,
        "From address is required"
      )
    end

    it "raises ValidationError when to is missing" do
      email = described_class.new(from: "a@b.com", text_body: "hi")

      expect { email.validate! }.to raise_error(
        PostmarkClient::ValidationError,
        "To address is required"
      )
    end

    it "raises ValidationError when both bodies are missing" do
      email = described_class.new(from: "a@b.com", to: "c@d.com")

      expect { email.validate! }.to raise_error(
        PostmarkClient::ValidationError,
        "Either HtmlBody or TextBody is required"
      )
    end

    it "raises ValidationError for invalid track_links value" do
      email = described_class.new(
        from: "a@b.com",
        to: "c@d.com",
        text_body: "hi",
        track_links: "Invalid"
      )

      expect { email.validate! }.to raise_error(
        PostmarkClient::ValidationError,
        /TrackLinks must be one of/
      )
    end

    it "accepts valid track_links values" do
      %w[None HtmlAndText HtmlOnly TextOnly].each do |value|
        email = described_class.new(
          from: "a@b.com",
          to: "c@d.com",
          text_body: "hi",
          track_links: value
        )

        expect(email.validate!).to be(true)
      end
    end
  end

  describe "#valid?" do
    it "returns true for valid email" do
      email = described_class.new(from: "a@b.com", to: "c@d.com", text_body: "hi")
      expect(email.valid?).to be(true)
    end

    it "returns false for invalid email" do
      email = described_class.new
      expect(email.valid?).to be(false)
    end
  end

  describe "#to_h" do
    it "converts email to API format hash" do
      email = described_class.new(
        from: "sender@example.com",
        to: "recipient@example.com",
        subject: "Test Subject",
        text_body: "Hello, World!",
        html_body: "<p>Hello, World!</p>",
        message_stream: "outbound"
      )

      hash = email.to_h

      expect(hash["From"]).to eq("sender@example.com")
      expect(hash["To"]).to eq("recipient@example.com")
      expect(hash["Subject"]).to eq("Test Subject")
      expect(hash["TextBody"]).to eq("Hello, World!")
      expect(hash["HtmlBody"]).to eq("<p>Hello, World!</p>")
      expect(hash["MessageStream"]).to eq("outbound")
    end

    it "joins array recipients with commas" do
      email = described_class.new(
        from: "a@b.com",
        to: ["x@y.com", "z@w.com"],
        cc: ["cc1@b.com", "cc2@b.com"],
        text_body: "hi"
      )

      hash = email.to_h

      expect(hash["To"]).to eq("x@y.com, z@w.com")
      expect(hash["Cc"]).to eq("cc1@b.com, cc2@b.com")
    end

    it "includes headers when present" do
      email = described_class.new(from: "a@b.com", to: "c@d.com", text_body: "hi")
      email.add_header(name: "X-Custom", value: "test")

      expect(email.to_h["Headers"]).to eq([{ "Name" => "X-Custom", "Value" => "test" }])
    end

    it "includes attachments when present" do
      email = described_class.new(from: "a@b.com", to: "c@d.com", text_body: "hi")
      email.add_attachment(name: "test.txt", content: "content", content_type: "text/plain")

      attachments = email.to_h["Attachments"]
      expect(attachments.first["Name"]).to eq("test.txt")
    end

    it "includes metadata when present" do
      email = described_class.new(
        from: "a@b.com",
        to: "c@d.com",
        text_body: "hi",
        metadata: { "color" => "blue" }
      )

      expect(email.to_h["Metadata"]).to eq("color" => "blue")
    end

    it "excludes nil and empty values" do
      email = described_class.new(
        from: "a@b.com",
        to: "c@d.com",
        text_body: "hi"
      )

      hash = email.to_h

      expect(hash).not_to have_key("Cc")
      expect(hash).not_to have_key("Bcc")
      expect(hash).not_to have_key("Subject")
      expect(hash).not_to have_key("HtmlBody")
      expect(hash).not_to have_key("Headers")
      expect(hash).not_to have_key("Attachments")
      expect(hash).not_to have_key("Metadata")
    end

    it "includes TrackOpens when explicitly set" do
      email = described_class.new(
        from: "a@b.com",
        to: "c@d.com",
        text_body: "hi",
        track_opens: false
      )

      expect(email.to_h["TrackOpens"]).to be(false)
    end
  end

  describe "#to_api_hash" do
    it "is an alias for to_h" do
      email = described_class.new(from: "a@b.com", to: "c@d.com", text_body: "hi")
      expect(email.to_api_hash).to eq(email.to_h)
    end
  end
end
