require 'ddtrace/contrib/support/spec_helper'

require 'ddtrace/contrib/configuration/resolver'

RSpec.describe Datadog::Contrib::Configuration::Resolver do
  subject(:resolver) { described_class.new(&default_config_block) }
  let(:default_config_block) { proc { config_class.new } }
  let(:config_class) { Class.new }
  let(:config) { double('config') }

  describe '#resolve' do
    subject(:resolve) { resolver.resolve(key) }
    let(:key) { double('key') }

    context 'with a matcher' do
      before { resolver.add(added_matcher, config) }

      context 'that matches' do
        let(:added_matcher) { key }
        it { is_expected.to be config }
      end

      context 'that does not match' do
        let(:added_matcher) { :different_value }
        it { is_expected.to be nil }
      end
    end

    context 'without a matcher' do
      it { is_expected.to be nil }
    end
  end

  describe '#add' do
    subject(:add) { resolver.add(key, config) }
    let(:key) { double('key') }
    it { is_expected.to be config }

    it 'stores in the configuration field' do
      add
      expect(resolver.configurations).to eq(key => config)
    end
  end
end
