# postmark_ruby_client

A clean, extensible Ruby client for the [Postmark](https://postmarkapp.com) transactional email API. Built with Faraday and designed for Rails 8+ applications.

## Features

- **Simple API**: Intuitive Ruby interface for sending emails
- **Extensible Design**: Base client class makes it easy to add new API endpoints
- **Full Email Support**: HTML/text bodies, attachments, custom headers, metadata, tracking
- **Batch Sending**: Send up to 500 emails in a single API call
- **Type Safety**: Validation before API calls to catch errors early
- **Configurable**: Global configuration with per-request overrides

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'postmark_ruby_client'
```

And then execute:

```bash
bundle install
```

Or install it yourself:

```bash
gem install postmark_ruby_client
```

## Configuration

Configure the gem with your Postmark server API token. In a Rails application, create an initializer:

```ruby
# config/initializers/postmark_ruby_client.rb
PostmarkClient.configure do |config|
  config.api_token = ENV["POSTMARK_API_TOKEN"]

  # Optional settings with defaults
  config.default_message_stream = "outbound"  # Default message stream
  config.timeout = 30                          # Request timeout in seconds
  config.open_timeout = 10                     # Connection timeout in seconds
  config.track_opens = false                   # Default open tracking
  config.track_links = "None"                  # Default link tracking
end
```

The API token can also be set via the `POSTMARK_API_TOKEN` environment variable.

## Usage

### Sending a Simple Email

```ruby
# Using the convenience method
response = PostmarkClient.deliver(
  from: "sender@example.com",
  to: "recipient@example.com",
  subject: "Hello!",
  text_body: "Hello, World!"
)

if response.success?
  puts "Email sent! Message ID: #{response.message_id}"
else
  puts "Error: #{response.message}"
end
```

### Using the Email Model

```ruby
email = PostmarkClient::Models::Email.new(
  from: "John Doe <john@example.com>",
  to: ["alice@example.com", "bob@example.com"],
  cc: "manager@example.com",
  bcc: "archive@example.com",
  subject: "Monthly Report",
  html_body: "<h1>Report</h1><p>See attached.</p>",
  text_body: "Report - See attached.",
  reply_to: "support@example.com",
  tag: "monthly-report",
  track_opens: true,
  track_links: "HtmlAndText",
  metadata: { "client_id" => "12345" }
)

client = PostmarkClient::Resources::Emails.new
response = client.send(email)
```

### Adding Attachments

```ruby
email = PostmarkClient::Models::Email.new(
  from: "sender@example.com",
  to: "recipient@example.com",
  subject: "Files attached",
  text_body: "Please see the attached files."
)

# Add attachment from parameters
email.add_attachment(
  name: "document.pdf",
  content: File.binread("path/to/document.pdf"),
  content_type: "application/pdf"
)

# Or attach directly from a file path
email.attach_file("path/to/image.png")

# Inline attachments for HTML emails
email.html_body = '<p>Logo: <img src="cid:logo.png"/></p>'
email.add_attachment(
  name: "logo.png",
  content: File.binread("logo.png"),
  content_type: "image/png",
  content_id: "cid:logo.png"
)
```

### Custom Headers

```ruby
email = PostmarkClient::Models::Email.new(
  from: "sender@example.com",
  to: "recipient@example.com",
  subject: "Custom headers",
  text_body: "Hello"
)

email.add_header(name: "X-Custom-Header", value: "custom-value")
email.add_header(name: "X-Priority", value: "1")
```

### Batch Sending

Send up to 500 emails in a single API call:

```ruby
emails = users.map do |user|
  {
    from: "notifications@example.com",
    to: user.email,
    subject: "Your weekly digest",
    text_body: "Here's what you missed..."
  }
end

client = PostmarkClient::Resources::Emails.new
responses = client.send_batch(emails)

responses.each do |response|
  if response.success?
    puts "Sent to #{response.to}"
  else
    puts "Failed: #{response.message}"
  end
end
```

### Using a Custom API Token

Override the global configuration for specific requests:

```ruby
# For a different Postmark server
client = PostmarkClient::Resources::Emails.new(api_token: "different-token")
response = client.send(email)

# Or with the convenience method
client = PostmarkClient.emails(api_token: "different-token")
response = client.send_email(
  from: "sender@example.com",
  to: "recipient@example.com",
  subject: "Hello",
  text_body: "World"
)
```

### Error Handling

```ruby
begin
  response = PostmarkClient.deliver(email)
rescue PostmarkClient::ValidationError => e
  # Email failed local validation before sending
  puts "Validation error: #{e.message}"
rescue PostmarkClient::ApiError => e
  # Postmark API returned an error
  puts "API error #{e.error_code}: #{e.message}"
  puts "Full response: #{e.response}"
rescue PostmarkClient::ConnectionError => e
  # Network connectivity issues
  puts "Connection error: #{e.message}"
rescue PostmarkClient::ConfigurationError => e
  # Missing or invalid configuration
  puts "Configuration error: #{e.message}"
end
```

## API Reference

### PostmarkClient::Models::Email

| Attribute | Type | Description |
|-----------|------|-------------|
| `from` | String | Sender email (required) |
| `to` | String/Array | Recipient email(s) (required) |
| `cc` | String/Array | CC recipient(s) |
| `bcc` | String/Array | BCC recipient(s) |
| `subject` | String | Email subject |
| `html_body` | String | HTML email body |
| `text_body` | String | Plain text body |
| `reply_to` | String | Reply-to address |
| `tag` | String | Email tag for categorization |
| `headers` | Array | Custom email headers |
| `track_opens` | Boolean | Enable open tracking |
| `track_links` | String | Link tracking ("None", "HtmlAndText", "HtmlOnly", "TextOnly") |
| `attachments` | Array | Email attachments |
| `metadata` | Hash | Custom metadata key-value pairs |
| `message_stream` | String | Message stream identifier |

### PostmarkClient::Models::EmailResponse

| Method | Returns | Description |
|--------|---------|-------------|
| `success?` | Boolean | True if email was sent successfully |
| `error?` | Boolean | True if there was an error |
| `message_id` | String | Unique message identifier |
| `to` | String | Recipient address |
| `submitted_at` | Time | Timestamp when email was submitted |
| `error_code` | Integer | Postmark error code (0 = success) |
| `message` | String | Response message |
| `raw_response` | Hash | Full API response |

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests.

```bash
# Install dependencies
bundle install

# Run tests
bundle exec rspec

# Generate documentation
bundle exec yard doc
```

# View documentation in browser
bundle exec yard server
# Then open http://localhost:8808


## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/yourusername/postmark_ruby_client.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin feature/my-new-feature`)
5. Create a new Pull Request

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Related Resources

- [Postmark API Documentation](https://postmarkapp.com/developer)
- [Postmark Email API Reference](https://postmarkapp.com/developer/api/email-api)
