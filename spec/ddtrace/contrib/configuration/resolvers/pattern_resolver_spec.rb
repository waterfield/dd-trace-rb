require 'ddtrace/contrib/support/spec_helper'
require 'ddtrace'

RSpec.describe Datadog::Contrib::Configuration::Resolvers::PatternResolver do
  subject(:resolver) { described_class.new }

  let(:config) { double('config') }

  describe '#resolve' do
    subject(:resolve) { resolver.resolve(name) }

    context 'when matching Regexp has been added' do
      let(:name) { 'my-name' }
      let(:matcher) { /name/ }

      before { resolver.add(matcher, config) }
      it { is_expected.to eq(config) }

      context 'then given a name that isn\'t a String but is case equal' do
        let(:name) { URI('http://localhost') }
        let(:matcher) { /#{Regexp.escape('http://localhost')}/ }

        it 'coerces the name to a String' do
          is_expected.to eq(config)
        end
      end
    end

    context 'when non-matching Regexp has been added' do
      let(:name) { 'my-name' }
      before { resolver.add(/not_found/, config) }
      it { is_expected.to be nil }
    end

    context 'when matching Proc has been added' do
      let(:name) { 'my-name' }
      let(:matcher_proc) { proc { |n| n == name } }
      before { resolver.add(matcher_proc, config) }
      it { is_expected.to eq(config) }

      context 'then given a name that isn\'t a String but is case equal' do
        let(:name) { URI('http://localhost') }
        let(:matcher_proc) { proc { |uri| uri.is_a?(URI) } }

        it 'does not coerce the name' do
          is_expected.to eq(config)
        end
      end
    end

    context 'when non-matching Proc has been added' do
      let(:name) { 'my-name' }
      before { resolver.add(proc { |n| n == 'not_found' }, config) }
      it { is_expected.to be nil }
    end

    context 'when a matching String has been added' do
      let(:name) { 'my-name' }
      let(:matcher) { name }

      before { resolver.add(matcher, config) }
      it { is_expected.to eq(config) }

      context 'then given a name that isn\'t a String but is case equal' do
        let(:name) { URI('http://localhost') }
        let(:matcher) { name.to_s }

        it 'coerces the name to a String' do
          is_expected.to eq(config)
        end
      end
    end

    context 'when a non-matching String has been added' do
      let(:name) { 'name' }
      before { resolver.add('my-name', config) }
      it { is_expected.to be nil }
    end
  end

  describe '#add' do
    subject(:add) { resolver.add(matcher, config) }

    context 'when given a Regexp' do
      let(:matcher) { /name/ }

      it 'allows any string matching the matcher to resolve' do
        expect { add }.to change { resolver.resolve('my-name') }
          .from(nil)
          .to(config)
      end
    end

    context 'when given a Proc' do
      let(:matcher) { proc { |n| n == 'my-name' } }

      it 'allows any string matching the matcher to resolve' do
        expect { add }.to change { resolver.resolve('my-name') }
          .from(nil)
          .to(config)
      end
    end

    context 'when given a string' do
      let(:matcher) { 'my-name' }

      it 'allows identical strings to resolve' do
        expect { add }.to change { resolver.resolve(matcher) }
          .from(nil)
          .to(config)
      end
    end

    context 'when given some object that responds to #to_s' do
      let(:matcher) { URI('http://localhost') }

      it 'allows its #to_s value to match identical strings when resolved' do
        expect(matcher).to respond_to(:to_s)
        expect { add }.to change { resolver.resolve('http://localhost') }
          .from(nil)
          .to(config)
      end
    end
  end
end
