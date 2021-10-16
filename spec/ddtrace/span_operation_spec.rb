# typed: ignore
require 'spec_helper'
require 'ddtrace/span_operation'

# rubocop:disable RSpec/EmptyExampleGroup
RSpec.describe Datadog::SpanOperation do
  subject(:span_op) { described_class.new(name, options) }
  let(:name) { 'my.operation' }
  let(:options) { {} }

  shared_examples 'a root span operation' do
    it do
      is_expected.to have_attributes(
        parent_id: 0,
        parent: nil,
      )

      # Because we maintain parallel "parent" state between
      # Span and Span Operation, ensure this matches.
      expect(span_op.span.parent).to be(nil)
    end

    it 'has default tags' do
      expect(span_op.get_tag(Datadog::Ext::Runtime::TAG_PID)).to eq(Process.pid)
      expect(span_op.get_tag(Datadog::Ext::Runtime::TAG_ID)).to eq(Datadog::Core::Environment::Identity.id)
    end
  end

  shared_examples 'a child span operation' do
    it 'associates to the parent' do
      is_expected.to have_attributes(
        parent: parent,
        parent_id: parent.span_id,
        trace_id: parent.trace_id
      )

      # Because we maintain parallel "parent" state between
      # Span and Span Operation, ensure this matches.
      expect(span_op.span.parent).to be(parent.span)
    end
  end

  describe 'forwarded methods' do
    [
      :allocations,
      :clear_metric,
      :clear_tag,
      :duration,
      :duration=,
      :end_time,
      :end_time=,
      :get_metric,
      :get_tag,
      :name,
      :name=,
      :parent_id,
      :parent_id=,
      :pretty_print,
      :resource,
      :resource=,
      :sampled,
      :sampled=,
      :service,
      :service=,
      :set_error,
      :set_metric,
      :set_parent,
      :set_tag,
      :set_tags,
      :span_id,
      :span_id=,
      :span_type,
      :span_type=,
      :start_time,
      :start_time=,
      :started?,
      :status,
      :status=,
      :stop,
      :stopped?,
      :to_hash,
      :to_json,
      :to_msgpack,
      :to_s,
      :trace_id,
      :trace_id=
    ].each do |forwarded_method|
      # rubocop:disable RSpec/VerifiedDoubles
      context "##{forwarded_method}" do
        let!(:args) { Array.new(arg_count < 0 ? 0 : arg_count) { double('arg') } }
        let!(:arg_count) { span_op.span.method(forwarded_method).arity }

        it 'forwards to the Span' do
          expect(span_op.span).to receive(forwarded_method).with(any_args)
          span_op.send(forwarded_method, *args)
        end
      end
      # rubocop:enable RSpec/VerifiedDoubles
    end
  end

  describe '::new' do
    context 'given only a name' do
      it do
        is_expected.to have_attributes(
          context: nil,
          end_time: nil,
          events: kind_of(described_class::Events),
          finished?: false,
          name: name,
          resource: name,
          sampled: true,
          service: nil,
          span_id: kind_of(Integer),
          span_type: nil,
          span: kind_of(Datadog::Span),
          start_time: nil,
          started?: false,
          stopped?: false,
          trace_id: kind_of(Integer),
        )
      end

      it_behaves_like 'a root span operation'
    end

    context 'given an option' do
      describe ':child_of' do
        let(:options) { { child_of: child_of } }

        context 'that is nil' do
          let(:child_of) { nil }
          it_behaves_like 'a root span operation'
        end

        context 'that is a SpanOperation' do
          let(:child_of) { parent }
          let(:parent) do
            described_class.new(
              'parent span',
              service: instance_double(String)
            )
          end

          context 'and no :service is given' do
            it_behaves_like 'a child span operation'

            it 'uses the parent span service' do
              is_expected.to have_attributes(
                service: parent.service
              )
            end
          end

          context 'and :service is given' do
            let(:options) { { child_of: parent, service: service } }
            let(:service) { instance_double(String) }

            it_behaves_like 'a child span operation'

            it 'uses the parent span service' do
              is_expected.to have_attributes(
                service: service
              )
            end
          end
        end
      end

      describe ':context' do
        let(:options) { { context: context } }

        context 'that is nil' do
          let(:context) { nil }

          it_behaves_like 'a root span operation'
        end

        context 'that is a Context' do
          let(:context) { instance_double(Datadog::Context) }

          it_behaves_like 'a root span operation'

          # It should not modify the context:
          # The tracer should be responsible for context management.
          # This association exists only for backwards compatibility.
          it 'associates with the Context' do
            is_expected.to have_attributes(context: context)
          end
        end
      end

      describe ':events' do
        let(:options) { { events: events } }
        let(:events) { instance_double(described_class::Events) }
      end

      describe ':parent_id' do
        let(:options) { { parent_id: parent_id } }
        let(:parent_id) { instance_double(Integer) }
      end

      describe ':resource' do
        let(:options) { { resource: resource } }
        let(:resource) { instance_double(String) }
      end

      describe ':service' do
        let(:options) { { service: service } }
        let(:service) { instance_double(String) }
      end

      describe ':span_type' do
        let(:options) { { span_type: span_type } }
        let(:span_type) { instance_double(String) }
      end

      describe ':tags' do
        let(:options) { { tags: tags } }
        let(:tags) { instance_double(Hash) }
      end

      describe ':trace_id' do
        let(:options) { { trace_id: trace_id } }
        let(:trace_id) { instance_double(Integer) }
      end
    end
  end

  describe '#measure' do
    # TODO
  end

  describe '#parent=' do
    # TODO
  end

  describe '#detach_from_context!' do
    # TODO
  end

  describe '#start' do
    # TODO
  end

  describe '#finish' do
    # TODO
  end

  describe '#finished?' do
    # TODO
  end
end

RSpec.describe Datadog::SpanOperation::Events do
  describe '::new' do
    # TODO
  end

  describe '#after_finish' do
    # TODO
  end

  describe '#before_start' do
    # TODO
  end

  describe '#on_error' do
    # TODO
  end
end
# rubocop:enable RSpec/EmptyExampleGroup

RSpec.describe Datadog::SpanOperation::Analytics do
  subject(:test_object) { test_class.new }

  describe '#set_tag' do
    subject(:set_tag) { test_object.set_tag(key, value) }

    before do
      allow(Datadog::Analytics).to receive(:set_sample_rate)
      set_tag
    end

    context 'when #set_tag is defined on the class' do
      let(:test_class) do
        Class.new do
          prepend Datadog::SpanOperation::Analytics

          # Define this method here to prove it doesn't
          # override behavior in Datadog::Analytics::Span.
          def set_tag(key, value)
            [key, value]
          end
        end
      end

      context 'and is given' do
        context 'some kind of tag' do
          let(:key) { 'my.tag' }
          let(:value) { 'my.value' }

          it 'calls the super #set_tag' do
            is_expected.to eq([key, value])
          end
        end

        context 'TAG_ENABLED with' do
          let(:key) { Datadog::Ext::Analytics::TAG_ENABLED }

          context 'true' do
            let(:value) { true }

            it do
              expect(Datadog::Analytics).to have_received(:set_sample_rate)
                .with(test_object, Datadog::Ext::Analytics::DEFAULT_SAMPLE_RATE)
            end
          end

          context 'false' do
            let(:value) { false }

            it do
              expect(Datadog::Analytics).to have_received(:set_sample_rate)
                .with(test_object, 0.0)
            end
          end

          context 'nil' do
            let(:value) { nil }

            it do
              expect(Datadog::Analytics).to have_received(:set_sample_rate)
                .with(test_object, 0.0)
            end
          end
        end

        context 'TAG_SAMPLE_RATE with' do
          let(:key) { Datadog::Ext::Analytics::TAG_SAMPLE_RATE }

          context 'a Float' do
            let(:value) { 0.5 }

            it do
              expect(Datadog::Analytics).to have_received(:set_sample_rate)
                .with(test_object, value)
            end
          end

          context 'a String' do
            let(:value) { '0.5' }

            it do
              expect(Datadog::Analytics).to have_received(:set_sample_rate)
                .with(test_object, value)
            end
          end

          context 'nil' do
            let(:value) { nil }

            it do
              expect(Datadog::Analytics).to have_received(:set_sample_rate)
                .with(test_object, value)
            end
          end
        end
      end
    end
  end
end

RSpec.describe Datadog::SpanOperation::ForcedTracing do
  subject(:test_object) { test_class.new }

  describe '#set_tag' do
    subject(:set_tag) { test_object.set_tag(key, value) }

    before do
      allow(Datadog::ForcedTracing).to receive(:keep)
      allow(Datadog::ForcedTracing).to receive(:drop)
      set_tag
    end

    context 'when #set_tag is defined on the class' do
      let(:span) do
        instance_double(Datadog::Span).tap do |span|
          allow(span).to receive(:set_tag)
        end
      end

      let(:test_class) do
        s = span

        klass = Class.new do
          prepend Datadog::SpanOperation::ForcedTracing
        end

        klass.tap do
          # Define this method here to prove it doesn't
          # override behavior in Datadog::Analytics::Span.
          klass.send(:define_method, :set_tag) do |key, value|
            s.set_tag(key, value)
          end
        end
      end

      context 'and is given' do
        context 'some kind of tag' do
          let(:key) { 'my.tag' }
          let(:value) { 'my.value' }

          it 'calls the super #set_tag' do
            expect(Datadog::ForcedTracing).to_not have_received(:keep)
            expect(Datadog::ForcedTracing).to_not have_received(:drop)
            expect(span).to have_received(:set_tag)
              .with(key, value)
          end
        end

        context 'TAG_KEEP with' do
          let(:key) { Datadog::Ext::ManualTracing::TAG_KEEP }

          context 'true' do
            let(:value) { true }

            it do
              expect(Datadog::ForcedTracing).to have_received(:keep)
                .with(test_object)
              expect(Datadog::ForcedTracing).to_not have_received(:drop)
              expect(span).to_not have_received(:set_tag)
            end
          end

          context 'false' do
            let(:value) { false }

            it do
              expect(Datadog::ForcedTracing).to_not have_received(:keep)
              expect(Datadog::ForcedTracing).to_not have_received(:drop)
              expect(span).to_not have_received(:set_tag)
            end
          end

          context 'nil' do
            let(:value) { nil }

            it do
              expect(Datadog::ForcedTracing).to have_received(:keep)
                .with(test_object)
              expect(Datadog::ForcedTracing).to_not have_received(:drop)
              expect(span).to_not have_received(:set_tag)
            end
          end
        end

        context 'TAG_DROP with' do
          let(:key) { Datadog::Ext::ManualTracing::TAG_DROP }

          context 'true' do
            let(:value) { true }

            it do
              expect(Datadog::ForcedTracing).to_not have_received(:keep)
              expect(Datadog::ForcedTracing).to have_received(:drop)
                .with(test_object)
              expect(span).to_not have_received(:set_tag)
            end
          end

          context 'false' do
            let(:value) { false }

            it do
              expect(Datadog::ForcedTracing).to_not have_received(:keep)
              expect(Datadog::ForcedTracing).to_not have_received(:drop)
              expect(span).to_not have_received(:set_tag)
            end
          end

          context 'nil' do
            let(:value) { nil }

            it do
              expect(Datadog::ForcedTracing).to_not have_received(:keep)
              expect(Datadog::ForcedTracing).to have_received(:drop)
                .with(test_object)
              expect(span).to_not have_received(:set_tag)
            end
          end
        end
      end
    end
  end
end
