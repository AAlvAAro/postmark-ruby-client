# frozen_string_literal: true

module PostmarkClient
  # Configuration class for PostmarkClient gem.
  # Stores global settings that apply to all API clients.
  #
  # @example Configuring the gem in a Rails initializer
  #   # config/initializers/postmark_ruby_client.rb
  #   PostmarkClient.configure do |config|
  #     config.api_token = ENV["POSTMARK_API_TOKEN"]
  #     config.default_message_stream = "outbound"
  #     config.timeout = 60
  #   end
  #
  # @example Accessing configuration
  #   PostmarkClient.configuration.api_token
  class Configuration
    # @return [String, nil] the Postmark server API token
    attr_accessor :api_token

    # @return [String] the default message stream for emails (default: "outbound")
    attr_accessor :default_message_stream

    # @return [Integer] request timeout in seconds (default: 30)
    attr_accessor :timeout

    # @return [Integer] connection open timeout in seconds (default: 10)
    attr_accessor :open_timeout

    # @return [Boolean] whether to track email opens by default (default: false)
    attr_accessor :track_opens

    # @return [String] default link tracking setting (default: "None")
    #   Valid values: "None", "HtmlAndText", "HtmlOnly", "TextOnly"
    attr_accessor :track_links

    # Initialize configuration with default values
    def initialize
      @api_token = ENV.fetch("POSTMARK_API_TOKEN", nil)
      @default_message_stream = "outbound"
      @timeout = 30
      @open_timeout = 10
      @track_opens = false
      @track_links = "None"
    end
  end

  class << self
    # @return [Configuration] the global configuration instance
    attr_writer :configuration

    # Get the current configuration, initializing if necessary
    #
    # @return [Configuration] the global configuration instance
    def configuration
      @configuration ||= Configuration.new
    end

    # Configure the gem using a block
    #
    # @yield [Configuration] the configuration instance
    # @return [void]
    #
    # @example
    #   PostmarkClient.configure do |config|
    #     config.api_token = "your-token"
    #   end
    def configure
      yield(configuration)
    end

    # Reset the configuration to defaults
    #
    # @return [void]
    def reset_configuration!
      @configuration = Configuration.new
    end
  end
end
