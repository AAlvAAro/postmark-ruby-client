# frozen_string_literal: true

require "faraday"
require "json"

module PostmarkClient
  module Client
    # Base client class for all Postmark API interactions.
    # Provides common HTTP functionality using Faraday.
    #
    # @example Creating a custom resource client
    #   class MyResource < PostmarkClient::Client::Base
    #     def fetch(id)
    #       get("/my-resource/#{id}")
    #     end
    #   end
    #
    # @abstract Subclass and implement specific API resource methods
    class Base
      # Postmark API base URL
      API_BASE_URL = "https://api.postmarkapp.com"

      # @return [String] the API token for authentication
      attr_reader :api_token

      # @return [Hash] additional options passed to the client
      attr_reader :options

      # Initialize a new API client
      #
      # @param api_token [String, nil] the Postmark server API token.
      #   Falls back to PostmarkClient.configuration.api_token if not provided.
      # @param options [Hash] additional configuration options
      # @option options [Integer] :timeout request timeout in seconds (default: 30)
      # @option options [Integer] :open_timeout connection open timeout in seconds (default: 10)
      # @option options [String] :base_url override the default API base URL
      #
      # @raise [PostmarkClient::ConfigurationError] if no API token is available
      def initialize(api_token: nil, **options)
        @api_token = api_token || PostmarkClient.configuration.api_token
        @options = options

        raise ConfigurationError, "API token is required" if @api_token.nil? || @api_token.empty?
      end

      protected

      # Perform a GET request to the Postmark API
      #
      # @param path [String] the API endpoint path
      # @param params [Hash] query parameters
      # @return [Hash] parsed JSON response
      def get(path, params = {})
        request(:get, path, params)
      end

      # Perform a POST request to the Postmark API
      #
      # @param path [String] the API endpoint path
      # @param body [Hash] request body
      # @return [Hash] parsed JSON response
      def post(path, body = {})
        request(:post, path, body)
      end

      # Perform a PUT request to the Postmark API
      #
      # @param path [String] the API endpoint path
      # @param body [Hash] request body
      # @return [Hash] parsed JSON response
      def put(path, body = {})
        request(:put, path, body)
      end

      # Perform a DELETE request to the Postmark API
      #
      # @param path [String] the API endpoint path
      # @param params [Hash] query parameters
      # @return [Hash] parsed JSON response
      def delete(path, params = {})
        request(:delete, path, params)
      end

      private

      # Build and return a configured Faraday connection
      #
      # @return [Faraday::Connection] configured connection instance
      def connection
        @connection ||= Faraday.new(url: base_url) do |conn|
          conn.request :json
          conn.response :json, content_type: /\bjson$/
          conn.response :raise_error

          conn.headers["Accept"] = "application/json"
          conn.headers["Content-Type"] = "application/json"
          conn.headers["X-Postmark-Server-Token"] = api_token

          conn.options.timeout = options.fetch(:timeout, 30)
          conn.options.open_timeout = options.fetch(:open_timeout, 10)

          conn.adapter Faraday.default_adapter
        end
      end

      # Get the base URL for API requests
      #
      # @return [String] the API base URL
      def base_url
        options.fetch(:base_url, API_BASE_URL)
      end

      # Perform an HTTP request and handle the response
      #
      # @param method [Symbol] HTTP method (:get, :post, :put, :delete)
      # @param path [String] the API endpoint path
      # @param payload [Hash] request body or query parameters
      # @return [Hash] parsed JSON response
      #
      # @raise [PostmarkClient::ApiError] on API error responses
      # @raise [PostmarkClient::ConnectionError] on network errors
      def request(method, path, payload = {})
        response = case method
                   when :get, :delete
                     connection.public_send(method, path, payload)
                   when :post, :put
                     connection.public_send(method, path, payload)
                   end

        response.body
      rescue Faraday::ClientError => e
        handle_client_error(e)
      rescue Faraday::ConnectionFailed, Faraday::TimeoutError => e
        raise ConnectionError, "Connection failed: #{e.message}"
      end

      # Handle Faraday client errors and raise appropriate exceptions
      #
      # @param error [Faraday::ClientError] the caught error
      # @raise [PostmarkClient::ApiError] with details from the response
      def handle_client_error(error)
        body = parse_error_body(error.response&.dig(:body))
        error_code = body["ErrorCode"] || error.response&.dig(:status)
        message = body["Message"] || error.message

        raise ApiError.new(message, error_code: error_code, response: body)
      end

      # Parse error body which may be a string or hash
      #
      # @param body [String, Hash, nil] the response body
      # @return [Hash] parsed body
      def parse_error_body(body)
        return {} if body.nil?
        return body if body.is_a?(Hash)

        JSON.parse(body)
      rescue JSON::ParserError
        {}
      end
    end
  end
end
