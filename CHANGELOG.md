# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.1.0] - 2026-01-15

### Added

- Initial release
- Email API support for sending single emails
- Email API support for batch sending (up to 500 emails)
- Email model with full Postmark API field support
- Attachment support with auto Base64 encoding
- File attachment helper method
- Inline attachment support for HTML emails
- Custom header support
- Metadata support
- Link and open tracking configuration
- Global configuration via initializer
- Per-request API token override
- Comprehensive error handling (ValidationError, ApiError, ConnectionError)
- Full RSpec test suite
- YARD documentation
