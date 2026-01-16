# frozen_string_literal: true

RSpec.describe PostmarkClient::Client::Base do
  let(:api_token) { "test-server-token" }
  let(:client) { described_class.new(api_token: api_token) }

  describe "#initialize" do
    it "accepts an API token parameter" do
      client = described_class.new(api_token: "my-token")
      expect(client.api_token).to eq("my-token")
    end

    it "falls back to configuration API token" do
      PostmarkClient.configure { |c| c.api_token = "config-token" }
      client = described_class.new

      expect(client.api_token).to eq("config-token")
    end

    it "raises ConfigurationError when no API token is available" do
      PostmarkClient.configure { |c| c.api_token = nil }

      expect { described_class.new }.to raise_error(
        PostmarkClient::ConfigurationError,
        "API token is required"
      )
    end

    it "raises ConfigurationError when API token is empty" do
      expect { described_class.new(api_token: "") }.to raise_error(
        PostmarkClient::ConfigurationError,
        "API token is required"
      )
    end

    it "stores additional options" do
      client = described_class.new(api_token: "token", timeout: 60)
      expect(client.options[:timeout]).to eq(60)
    end
  end

  describe "HTTP methods" do
    let(:test_client) do
      Class.new(described_class) do
        def test_get(path, params = {})
          get(path, params)
        end

        def test_post(path, body = {})
          post(path, body)
        end

        def test_put(path, body = {})
          put(path, body)
        end

        def test_delete(path, params = {})
          delete(path, params)
        end
      end.new(api_token: api_token)
    end

    describe "#get" do
      it "sends a GET request with correct headers" do
        stub_request(:get, stub_postmark_url("/test"))
          .with(
            headers: {
              "Accept" => "application/json",
              "Content-Type" => "application/json",
              "X-Postmark-Server-Token" => api_token
            }
          )
          .to_return(status: 200, body: '{"status": "ok"}', headers: { "Content-Type" => "application/json" })

        response = test_client.test_get("/test")
        expect(response).to eq("status" => "ok")
      end

      it "includes query parameters" do
        stub_request(:get, stub_postmark_url("/test"))
          .with(query: { page: "1", count: "10" })
          .to_return(status: 200, body: '{}', headers: { "Content-Type" => "application/json" })

        test_client.test_get("/test", { page: "1", count: "10" })

        expect(WebMock).to have_requested(:get, stub_postmark_url("/test")).with(query: { page: "1", count: "10" })
      end
    end

    describe "#post" do
      it "sends a POST request with JSON body" do
        stub_request(:post, stub_postmark_url("/test"))
          .with(body: { "data" => "value" })
          .to_return(status: 200, body: '{"created": true}', headers: { "Content-Type" => "application/json" })

        response = test_client.test_post("/test", { "data" => "value" })
        expect(response).to eq("created" => true)
      end
    end

    describe "#put" do
      it "sends a PUT request with JSON body" do
        stub_request(:put, stub_postmark_url("/test"))
          .with(body: { "updated" => "data" })
          .to_return(status: 200, body: '{"updated": true}', headers: { "Content-Type" => "application/json" })

        response = test_client.test_put("/test", { "updated" => "data" })
        expect(response).to eq("updated" => true)
      end
    end

    describe "#delete" do
      it "sends a DELETE request" do
        stub_request(:delete, stub_postmark_url("/test"))
          .to_return(status: 200, body: '{"deleted": true}', headers: { "Content-Type" => "application/json" })

        response = test_client.test_delete("/test")
        expect(response).to eq("deleted" => true)
      end
    end
  end

  describe "error handling" do
    let(:test_client) do
      Class.new(described_class) do
        def test_get(path)
          get(path)
        end
      end.new(api_token: api_token)
    end

    it "raises ApiError on 4xx responses" do
      stub_request(:get, stub_postmark_url("/error"))
        .to_return(
          status: 422,
          body: '{"ErrorCode": 300, "Message": "Invalid email address"}',
          headers: { "Content-Type" => "application/json" }
        )

      expect { test_client.test_get("/error") }.to raise_error(PostmarkClient::ApiError) do |error|
        expect(error.error_code).to eq(300)
        expect(error.message).to eq("Invalid email address")
      end
    end

    it "raises ConnectionError on network failures" do
      stub_request(:get, stub_postmark_url("/timeout"))
        .to_timeout

      expect { test_client.test_get("/timeout") }.to raise_error(
        PostmarkClient::ConnectionError,
        /Connection failed/
      )
    end

    it "raises ConnectionError on connection failures" do
      stub_request(:get, stub_postmark_url("/fail"))
        .to_raise(Faraday::ConnectionFailed.new("Connection refused"))

      expect { test_client.test_get("/fail") }.to raise_error(
        PostmarkClient::ConnectionError,
        /Connection failed/
      )
    end
  end

  describe "custom options" do
    it "uses custom base URL when provided" do
      custom_client = Class.new(described_class) do
        def test_get(path)
          get(path)
        end
      end.new(api_token: api_token, base_url: "https://custom.api.com")

      stub_request(:get, "https://custom.api.com/test")
        .to_return(status: 200, body: '{}', headers: { "Content-Type" => "application/json" })

      custom_client.test_get("/test")

      expect(WebMock).to have_requested(:get, "https://custom.api.com/test")
    end
  end
end
