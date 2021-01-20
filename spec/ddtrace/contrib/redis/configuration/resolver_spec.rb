require 'ddtrace/contrib/support/spec_helper'

require 'redis'
require 'ddtrace'

RSpec.describe 'Redis configuration resolver' do
  let(:resolver) { Datadog::Contrib::Redis::Configuration::Resolver.new }

  let(:config) { double('config') }
  let(:matcher) {}

  context '#add' do
    subject(:add) { resolver.add(matcher, config) }
    before { subject }

    let(:parsed_key) do
      expect(resolver.configurations.keys).to have(1).item
      resolver.configurations.keys[0]
    end

    context 'when unix socket provided' do
      let(:matcher) { { url: 'unix://path/to/file' } }

      it { expect(parsed_key).to eq(url: 'unix://path/to/file') }
    end

    context 'when redis connexion string provided' do
      let(:matcher) { { url: 'redis://127.0.0.1:6379/0' } }

      it do
        expect(parsed_key).to eq(host: '127.0.0.1',
                                 port: 6379,
                                 db: 0,
                                 scheme: 'redis')
      end
    end

    context 'when host, port, db and scheme provided' do
      let(:matcher) do
        {
          host: '127.0.0.1',
          port: 6379,
          db: 0,
          scheme: 'redis'
        }
      end

      it do
        expect(parsed_key).to eq(host: '127.0.0.1',
                                 port: 6379,
                                 db: 0,
                                 scheme: 'redis')
      end
    end

    context 'when host, port, and db are provided' do
      let(:matcher) do
        {
          host: '127.0.0.1',
          port: 6379,
          db: 0
        }
      end

      it do
        expect(parsed_key).to eq(host: '127.0.0.1',
                                 port: 6379,
                                 db: 0,
                                 scheme: 'redis')
      end
    end

    context 'when host and port are provided' do
      let(:matcher) do
        {
          host: '127.0.0.1',
          port: 6379
        }
      end

      it do
        expect(parsed_key).to eq(host: '127.0.0.1',
                                 port: 6379,
                                 db: 0,
                                 scheme: 'redis')
      end
    end
  end

  context '#resolve' do
    subject(:resolve) { resolver.resolve(matcher) }

    before { resolver.add(matcher, config) }

    context 'when unix socket provided' do
      let(:matcher) { { url: 'unix://path/to/file' } }

      it_behaves_like 'a resolver with a matching pattern'
    end

    context 'when redis connexion string provided' do
      let(:matcher) { { url: 'redis://127.0.0.1:6379/0' } }

      it_behaves_like 'a resolver with a matching pattern'
    end

    context 'when host, port, db and scheme provided' do
      let(:matcher) do
        {
          host: '127.0.0.1',
          port: 6379,
          db: 0,
          scheme: 'redis'
        }
      end

      it_behaves_like 'a resolver with a matching pattern'
    end

    context 'when host, port, and db are provided' do
      let(:matcher) do
        {
          host: '127.0.0.1',
          port: 6379,
          db: 0
        }
      end

      it_behaves_like 'a resolver with a matching pattern'
    end

    context 'when host and port are provided' do
      let(:matcher) do
        {
          host: '127.0.0.1',
          port: 6379
        }
      end

      it_behaves_like 'a resolver with a matching pattern'
    end
  end
end
