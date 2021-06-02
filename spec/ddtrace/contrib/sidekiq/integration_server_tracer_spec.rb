require 'ddtrace/contrib/support/spec_helper'

require_relative 'support/integration_worker'

require 'datadog/statsd'
require 'sidekiq'

RSpec.describe 'Integration Server tracer' do
  let(:redis_host) { ENV.fetch('TEST_REDIS_HOST', '127.0.0.1') }
  let(:redis_port) { ENV.fetch('TEST_REDIS_PORT', 6379) }

  before do
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with('REDIS_URL').and_return("redis://#{redis_host}:#{redis_port}")
  end

  subject do
    use_real_tracer!

    Datadog.configure do |c|
      c.use :sidekiq, service_name: "name_sidekiq", client_service_name: "name_sidekiq", tag_args: true
    end

    Sidekiq.configure_client do |config|
      config.logger.level = Logger::WARN # Reduce Sidekiq logging level
    end

    Sidekiq.configure_server do |config|
      config.logger.level = Logger::WARN # Reduce Sidekiq logging level
    end

    # Equivalent to `bin/sidekiq -r support/integration_worker.rb`
    # Source: https://github.com/mperham/sidekiq/blob/v6.1.3/bin/sidekiq
    $TESTING = false
    require 'sidekiq/cli'
    cli = Sidekiq::CLI.instance
    cli.parse(['-r', File.join(__dir__, 'support', 'integration_worker.rb')])
    Thread.new { cli.run }
  end

  it do
    subject

    IntegrationWorker.perform_async

    sleep 3600
  end
end
