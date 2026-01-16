# frozen_string_literal: true

RSpec.describe PostmarkClient::Configuration do
  subject(:configuration) { described_class.new }

  describe "#initialize" do
    it "sets default values" do
      # Reset to get clean state without test token
      PostmarkClient.reset_configuration!

      expect(configuration.default_message_stream).to eq("outbound")
      expect(configuration.timeout).to eq(30)
      expect(configuration.open_timeout).to eq(10)
      expect(configuration.track_opens).to be(false)
      expect(configuration.track_links).to eq("None")
    end

    it "reads API token from environment variable" do
      allow(ENV).to receive(:fetch).with("POSTMARK_API_TOKEN", nil).and_return("env-token")

      config = described_class.new
      expect(config.api_token).to eq("env-token")
    end
  end
end

RSpec.describe PostmarkClient do
  describe ".configure" do
    it "yields the configuration object" do
      expect { |b| described_class.configure(&b) }.to yield_with_args(
        PostmarkClient::Configuration
      )
    end

    it "allows setting configuration values" do
      described_class.configure do |config|
        config.api_token = "my-api-token"
        config.timeout = 60
      end

      expect(described_class.configuration.api_token).to eq("my-api-token")
      expect(described_class.configuration.timeout).to eq(60)
    end
  end

  describe ".configuration" do
    it "returns the same configuration instance" do
      config1 = described_class.configuration
      config2 = described_class.configuration

      expect(config1).to be(config2)
    end
  end

  describe ".reset_configuration!" do
    it "creates a new configuration instance" do
      original = described_class.configuration
      described_class.reset_configuration!

      expect(described_class.configuration).not_to be(original)
    end
  end
end
