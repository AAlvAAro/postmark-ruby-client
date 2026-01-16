# frozen_string_literal: true

RSpec.describe PostmarkClient::Resources::Emails do
  let(:api_token) { "test-api-token" }
  let(:client) { described_class.new(api_token: api_token) }

  describe "#send" do
    let(:email) do
      PostmarkClient::Email.new(
        from: "sender@example.com",
        to: "recipient@example.com",
        subject: "Test Subject",
        text_body: "Hello, World!"
      )
    end

    context "with Email model" do
      it "sends email and returns EmailResponse" do
        stub_request(:post, stub_postmark_url("/email"))
          .with(body: hash_including("From" => "sender@example.com"))
          .to_return(
            status: 200,
            body: successful_email_response.to_json,
            headers: { "Content-Type" => "application/json" }
          )

        response = client.send(email)

        expect(response).to be_a(PostmarkClient::EmailResponse)
        expect(response.success?).to be(true)
        expect(response.message_id).to eq("abc123-def456-ghi789")
      end

      it "sends correct request body" do
        stub_request(:post, stub_postmark_url("/email"))
          .to_return(
            status: 200,
            body: successful_email_response.to_json,
            headers: { "Content-Type" => "application/json" }
          )

        client.send(email)

        expect(WebMock).to have_requested(:post, stub_postmark_url("/email"))
          .with(body: hash_including(
            "From" => "sender@example.com",
            "To" => "recipient@example.com",
            "Subject" => "Test Subject",
            "TextBody" => "Hello, World!",
            "MessageStream" => "outbound"
          ))
      end

      it "includes authentication header" do
        stub_request(:post, stub_postmark_url("/email"))
          .to_return(
            status: 200,
            body: successful_email_response.to_json,
            headers: { "Content-Type" => "application/json" }
          )

        client.send(email)

        expect(WebMock).to have_requested(:post, stub_postmark_url("/email"))
          .with(headers: { "X-Postmark-Server-Token" => api_token })
      end
    end

    context "with Hash input" do
      it "converts hash to Email and sends" do
        stub_request(:post, stub_postmark_url("/email"))
          .to_return(
            status: 200,
            body: successful_email_response.to_json,
            headers: { "Content-Type" => "application/json" }
          )

        response = client.send(
          from: "sender@example.com",
          to: "recipient@example.com",
          text_body: "Hello"
        )

        expect(response.success?).to be(true)
      end

      it "handles Postmark API format keys" do
        stub_request(:post, stub_postmark_url("/email"))
          .to_return(
            status: 200,
            body: successful_email_response.to_json,
            headers: { "Content-Type" => "application/json" }
          )

        client.send(
          "From" => "sender@example.com",
          "To" => "recipient@example.com",
          "TextBody" => "Hello"
        )

        expect(WebMock).to have_requested(:post, stub_postmark_url("/email"))
          .with(body: hash_including("From" => "sender@example.com"))
      end
    end

    context "validation" do
      it "raises ValidationError for invalid email" do
        invalid_email = PostmarkClient::Email.new(from: "sender@example.com")

        expect { client.send(invalid_email) }.to raise_error(PostmarkClient::ValidationError)
      end
    end

    context "API errors" do
      it "raises ApiError on error response" do
        stub_request(:post, stub_postmark_url("/email"))
          .to_return(
            status: 422,
            body: error_email_response(code: 300, message: "Invalid email address").to_json,
            headers: { "Content-Type" => "application/json" }
          )

        expect { client.send(email) }.to raise_error(PostmarkClient::ApiError) do |error|
          expect(error.error_code).to eq(300)
          expect(error.message).to eq("Invalid email address")
        end
      end
    end
  end

  describe "#send_email" do
    it "sends email with keyword arguments" do
      stub_request(:post, stub_postmark_url("/email"))
        .to_return(
          status: 200,
          body: successful_email_response.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      response = client.send_email(
        from: "sender@example.com",
        to: "recipient@example.com",
        subject: "Hello!",
        text_body: "World",
        track_opens: true
      )

      expect(response.success?).to be(true)
      expect(WebMock).to have_requested(:post, stub_postmark_url("/email"))
        .with(body: hash_including(
          "From" => "sender@example.com",
          "To" => "recipient@example.com",
          "Subject" => "Hello!",
          "TextBody" => "World",
          "TrackOpens" => true
        ))
    end

    it "supports HTML body" do
      stub_request(:post, stub_postmark_url("/email"))
        .to_return(
          status: 200,
          body: successful_email_response.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      client.send_email(
        from: "a@b.com",
        to: "c@d.com",
        subject: "Test",
        html_body: "<p>Hello</p>"
      )

      expect(WebMock).to have_requested(:post, stub_postmark_url("/email"))
        .with(body: hash_including("HtmlBody" => "<p>Hello</p>"))
    end
  end

  describe "#send_batch" do
    let(:emails) do
      [
        { from: "a@example.com", to: "b@example.com", subject: "Test 1", text_body: "Hello 1" },
        { from: "a@example.com", to: "c@example.com", subject: "Test 2", text_body: "Hello 2" }
      ]
    end

    it "sends batch of emails" do
      batch_response = [
        successful_email_response(to: "b@example.com"),
        successful_email_response(to: "c@example.com")
      ]

      stub_request(:post, stub_postmark_url("/email/batch"))
        .to_return(
          status: 200,
          body: batch_response.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      responses = client.send_batch(emails)

      expect(responses.length).to eq(2)
      expect(responses).to all(be_a(PostmarkClient::EmailResponse))
      expect(responses.first.to).to eq("b@example.com")
      expect(responses.last.to).to eq("c@example.com")
    end

    it "raises ArgumentError for batches exceeding 500" do
      large_batch = Array.new(501) do |i|
        { from: "a@b.com", to: "c#{i}@d.com", text_body: "hi" }
      end

      expect { client.send_batch(large_batch) }.to raise_error(
        ArgumentError,
        "Batch cannot exceed 500 emails"
      )
    end

    it "validates all emails before sending" do
      invalid_batch = [
        { from: "a@b.com", to: "c@d.com", text_body: "valid" },
        { from: "a@b.com" } # missing to and body
      ]

      expect { client.send_batch(invalid_batch) }.to raise_error(PostmarkClient::ValidationError)
    end
  end
end
