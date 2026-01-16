# frozen_string_literal: true

RSpec.describe PostmarkClient::Models::EmailResponse do
  describe "#initialize" do
    it "parses response attributes" do
      response = described_class.new(
        "To" => "recipient@example.com",
        "SubmittedAt" => "2024-01-15T10:30:00.0000000-05:00",
        "MessageID" => "abc123-def456",
        "ErrorCode" => 0,
        "Message" => "OK"
      )

      expect(response.to).to eq("recipient@example.com")
      expect(response.message_id).to eq("abc123-def456")
      expect(response.error_code).to eq(0)
      expect(response.message).to eq("OK")
    end

    it "parses submitted_at as Time object" do
      response = described_class.new(
        "SubmittedAt" => "2024-01-15T10:30:00.0000000-05:00",
        "ErrorCode" => 0
      )

      expect(response.submitted_at).to be_a(Time)
      expect(response.submitted_at.year).to eq(2024)
      expect(response.submitted_at.month).to eq(1)
      expect(response.submitted_at.day).to eq(15)
    end

    it "handles nil submitted_at" do
      response = described_class.new("ErrorCode" => 0)
      expect(response.submitted_at).to be_nil
    end

    it "stores raw response" do
      raw = { "To" => "test@example.com", "ErrorCode" => 0, "CustomField" => "value" }
      response = described_class.new(raw)

      expect(response.raw_response).to eq(raw)
    end
  end

  describe "#success?" do
    it "returns true when error_code is 0" do
      response = described_class.new("ErrorCode" => 0)
      expect(response.success?).to be(true)
    end

    it "returns false when error_code is non-zero" do
      response = described_class.new("ErrorCode" => 300)
      expect(response.success?).to be(false)
    end
  end

  describe "#error?" do
    it "returns false when error_code is 0" do
      response = described_class.new("ErrorCode" => 0)
      expect(response.error?).to be(false)
    end

    it "returns true when error_code is non-zero" do
      response = described_class.new("ErrorCode" => 300)
      expect(response.error?).to be(true)
    end
  end

  describe "#to_s" do
    it "returns success message for successful responses" do
      response = described_class.new(
        "To" => "test@example.com",
        "MessageID" => "abc123",
        "ErrorCode" => 0
      )

      expect(response.to_s).to eq("Email sent to test@example.com (Message ID: abc123)")
    end

    it "returns error message for failed responses" do
      response = described_class.new(
        "ErrorCode" => 300,
        "Message" => "Invalid email address"
      )

      expect(response.to_s).to eq("Error 300: Invalid email address")
    end
  end
end
