# frozen_string_literal: true

RSpec.describe PostmarkClient do
  describe ".emails" do
    it "returns an Emails client instance" do
      client = described_class.emails

      expect(client).to be_a(PostmarkClient::Resources::Emails)
    end

    it "accepts custom API token" do
      client = described_class.emails(api_token: "custom-token")

      expect(client.api_token).to eq("custom-token")
    end
  end

  describe ".deliver" do
    let(:email_hash) do
      {
        from: "sender@example.com",
        to: "recipient@example.com",
        subject: "Test",
        text_body: "Hello"
      }
    end

    it "sends email from hash" do
      stub_request(:post, "https://api.postmarkapp.com/email")
        .to_return(
          status: 200,
          body: {
            "To" => "recipient@example.com",
            "MessageID" => "test-id",
            "ErrorCode" => 0,
            "Message" => "OK"
          }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      response = described_class.deliver(email_hash)

      expect(response.success?).to be(true)
    end

    it "sends Email model" do
      email = PostmarkClient::Email.new(**email_hash)

      stub_request(:post, "https://api.postmarkapp.com/email")
        .to_return(
          status: 200,
          body: {
            "To" => "recipient@example.com",
            "MessageID" => "test-id",
            "ErrorCode" => 0,
            "Message" => "OK"
          }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      response = described_class.deliver(email)

      expect(response.success?).to be(true)
    end
  end

  describe "VERSION" do
    it "has a version number" do
      expect(PostmarkClient::VERSION).not_to be_nil
      expect(PostmarkClient::VERSION).to match(/^\d+\.\d+\.\d+/)
    end
  end
end
