require 'ddtrace/contrib/support/spec_helper'

require_relative 'support/integration_worker'

require 'sidekiq'

$TESTING = false
require 'sidekiq/cli'

RSpec.describe 'Integration Server tracer' do
  let(:redis_host) { ENV.fetch('TEST_REDIS_HOST', '127.0.0.1') }
  let(:redis_port) { ENV.fetch('TEST_REDIS_PORT', 6379) }

  before do
    # Sidekiq::Testing.server_middleware.clear
    # Sidekiq::Testing.server_middleware do |chain|
    #   chain.add(Datadog::Contrib::Sidekiq::ServerTracer)
    # end

    Sidekiq::Extensions.enable_delay! if Sidekiq::VERSION > '5.0.0'
  end

  subject do
    enable datadog
    cli = Sidekiq::CLI.instance
    cli.parse([ '-r', File.join(__dir__, 'support', 'integration_worker.rb')])
    Thread.new { cli.run }
  end

  context 'with custom job' do
    before do
      stub_const('CustomWorker', Class.new do
        include Sidekiq::Worker

        def self.datadog_tracer_config
          { service_name: 'sidekiq-slow', tag_args: true }
        end

        def perform(_) end
      end)
    end

    it 'traces async job run' do
      subject

      IntegrationWorker.perform_async

      sleep 3600

      expect(spans).to have(4).items

      custom, empty, _push, _push = spans

      expect(empty.service).to eq('sidekiq')
      expect(empty.resource).to eq('EmptyWorker')
      expect(empty.get_tag('sidekiq.job.queue')).to eq('default')
      expect(empty.get_tag('sidekiq.job.delay')).to_not be_nil
      expect(empty.status).to eq(0)
      expect(empty.parent).to be_nil
      expect(empty.get_metric('_dd.measured')).to eq(1.0)

      expect(custom.service).to eq('sidekiq-slow')
      expect(custom.resource).to eq('CustomWorker')
      expect(custom.get_tag('sidekiq.job.queue')).to eq('default')
      expect(custom.status).to eq(0)
      expect(custom.parent).to be_nil
      expect(custom.get_tag('sidekiq.job.args')).to eq(['random_id'].to_s)
      expect(custom.get_metric('_dd.measured')).to eq(1.0)
    end
  end
end
