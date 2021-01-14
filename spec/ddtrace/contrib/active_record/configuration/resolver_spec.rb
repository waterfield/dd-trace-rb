require 'ddtrace/contrib/support/spec_helper'

require 'active_record'
require 'ddtrace/contrib/active_record/configuration/resolver'

RSpec.describe Datadog::Contrib::ActiveRecord::Configuration::Resolver do
  subject(:resolver) { described_class.new(configuration) }
  let(:configuration) { nil }

  # Wraps hashes in the same HashKey class used by the resolver
  def wrap_config(hash)
    Datadog::Contrib::ActiveRecord::Configuration::Resolver::HashKey.new(hash)
  end

  context '#resolve' do
    subject(:resolve) { resolver.resolve(actual) }

    context 'with a hash matcher' do
      let(:actual) do
        {
          adapter: 'adapter',
          host: 'host',
          port: 123,
          database: 'database',
          username: 'username',
          role: 'role'
        }
      end

      let(:matchers) do
        [matcher]
      end

      let(:resolved) do
        list = matchers.map { |m| [wrap_config(m), m] }
        Hash[list][resolve]
      end

      let(:match_all) { {} }

      context 'with exact match' do
        let(:matcher) do
          {
            adapter: 'adapter',
            host: 'host',
            port: 123,
            database: 'database',
            username: 'username',
            role: 'role'
          }
        end

        it do
          expect(resolved).to be(matcher)
        end
      end

      context 'with an empty matcher' do
        let(:matcher) { match_all }

        it 'matches all' do
          expect(resolved).to be(matcher)
        end
      end

      context 'with partial match' do
        context 'that matches' do
          let(:matcher) do
            {
              adapter: 'adapter'
            }
          end

          it do
            expect(resolved).to be(matcher)
          end
        end

        context 'that does not match' do
          let(:matcher) do
            {
              adapter: 'not matching'
            }
          end

          it do
            expect(resolved).to be_nil
          end
        end

        context 'with a makara connection' do
          let(:actual) do
            {
              name: 'master/1'
            }
          end

          let(:matcher) do
            {
              role: 'master'
            }
          end

          it 'resolves role from name' do
            expect(resolved).to be(matcher)
          end
        end
      end

      context 'with multiple matchers' do
        let(:matchers) { [first_matcher, second_matcher] }

        context 'that do not match' do
          let(:first_matcher) do
            {
              port: 0
            }
          end

          let(:second_matcher) do
            {
              adapter: 'not matching'
            }
          end

          it do
            expect(resolved).to be_nil
          end
        end

        context 'when the first one matches' do
          let(:first_matcher) do
            {
              database: 'database'
            }
          end

          let(:second_matcher) do
            {
              database: 'not correct'
            }
          end

          it do
            expect(resolved).to be(first_matcher)
          end
        end

        context 'when the second one matches' do
          let(:first_matcher) do
            {
              database: 'not right'
            }
          end

          let(:second_matcher) do
            {
              database: 'database'
            }
          end

          it do
            expect(resolved).to be(second_matcher)
          end
        end

        context 'when all match' do
          context 'and are the same matcher' do
            let(:first_matcher) do
              {
                host: 'host'
              }
            end

            let(:second_matcher) do
              {
                host: 'host'
              }
            end

            it 'replaces matcher, returning the latest matcher' do
              expect(resolved).to be(second_matcher)
            end
          end

          context 'and are not same matcher' do
            let(:first_matcher) do
              {
                host: 'host'
              }
            end

            let(:second_matcher) { match_all }

            it 'returns the first matcher to match' do
              expect(resolved).to be(first_matcher)
            end
          end
        end
      end
    end

    context 'with a symbol matcher' do
      let(:actual) { :test }

      context 'with a valid ActiveRecord database' do
        let(:configuration) { { 'test' => db_config } }

        let(:db_config) do
          {
            adapter: 'adapter',
            host: 'host',
            port: 123,
            database: 'database',
            username: 'username',
            role: 'test'
          }
        end

        it 'resolves to a normalized hash matcher' do
          is_expected.to eq(wrap_config(db_config))
        end
      end

      context 'without a valid ActiveRecord database' do
        it 'resolves to a normalized hash matcher' do
          expect(Datadog.logger).to receive(:error).with(/:test/)

          is_expected.to be_instance_of(Object)
        end
      end
    end

    context 'with a string URL matcher' do
      let(:actual) { 'adapter://host' }

      let(:normalized_config) do
        {
          adapter: 'adapter',
          host: 'host',
          port: nil,
          database: nil,
          username: nil,
          role: nil
        }
      end

      it 'resolves to a normalized hash matcher' do
        is_expected.to eq(wrap_config(normalized_config))
      end
    end
  end

  context '#add' do
    subject(:resolve) { resolver.add(key) }

    let(:key) { double }

    it 'returns the object provided without any changes' do
      is_expected.to be(key)
    end
  end
end
