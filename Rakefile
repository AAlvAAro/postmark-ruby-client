# frozen_string_literal: true

require "bundler/gem_tasks"
require "rspec/core/rake_task"

RSpec::Core::RakeTask.new(:spec)

task default: %i[spec]

namespace :doc do
  desc "Generate YARD documentation"
  task :yard do
    sh "yard doc --output-dir doc/yard"
  end
end

desc "Open an IRB console with the gem loaded"
task :console do
  require "irb"
  require "postmark_ruby_client"

  ARGV.clear
  IRB.start
end
