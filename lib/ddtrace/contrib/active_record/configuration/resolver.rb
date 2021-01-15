require 'ddtrace/contrib/configuration/resolver'
require 'ddtrace/vendor/active_record/connection_specification'

module Datadog
  module Contrib
    module ActiveRecord
      module Configuration
        # Converts Symbols, Strings, and Hashes to a normalized connection settings Hash.
        class Resolver < Contrib::Configuration::Resolver
          def initialize(ar_configurations = nil)
            super()

            @ar_configurations = ar_configurations
          end

          def ar_configurations
            @ar_configurations || ::ActiveRecord::Base.configurations
          end

          def add(pattern, value)
            resolved_pattern = connection_resolver.resolve(pattern).symbolize_keys

            normalized = normalize(resolved_pattern)

            # Remove empty fields to allow for partial matching
            normalized.reject! { |_, v| v.nil? }

            super(normalized, value)
          end

          def resolve(key)
            ar_config = connection_resolver.resolve(key).symbolize_keys

            hash = normalize(ar_config)
            inject_makara_role!(hash, ar_config)

            # Hashes in Ruby maintain insertion order
            _, config = @configurations.find do |pattern, _|
              pattern.none? do |key, value|
                value != hash[key]
              end
            end

            config
          rescue => e
            Datadog.logger.error(
              "Failed to resolve ActiveRecord configuration key #{key.inspect}. " \
              "Cause: #{e.message} Source: #{e.backtrace.first}"
            )

            nil
          end

          private

          # Class that allows the returned hash key
          # to partially match the desired configuration
          # with the actual database settings.
          # class HashKey
          #   def initialize(hash)
          #     @hash = hash
          #   end
          #
          #   # `#hash` is a reserved method name
          #   def _hash
          #     @hash
          #   end
          #
          #   def eql?(other)
          #     other._hash.none? do |key, value|
          #       value != @hash[key]
          #     end
          #     # other.hash
          #     #
          #     # unless other.a.nil?
          #     #   return false unless other.a == a
          #     # end
          #     #
          #     # unless other.b.nil?
          #     #   return false unless other.b == b
          #     # end
          #     #
          #     # true
          #   end
          #
          #   # It is not possible to crate a hash number
          #   # that will still allow us to match keys with
          #   # the flexibility we need.
          #   #
          #   # We then set all hash elements to the same value
          #   # to force a sequential scan of all keys.
          #   def hash
          #     0
          #   end
          #
          #   def ==(other)
          #     other.is_a?(HashKey) &&
          #       @hash == other._hash
          #   end
          #
          #   def to_s
          #     "#{self.class}:#{@hash}"
          #   end
          # end

          def connection_resolver
            @resolver ||= begin
              if defined?(::ActiveRecord::ConnectionAdapters::ConnectionSpecification::Resolver)
                ::ActiveRecord::ConnectionAdapters::ConnectionSpecification::Resolver.new(ar_configurations)
              else
                ::Datadog::Vendor::ActiveRecord::ConnectionAdapters::ConnectionSpecification::Resolver.new(ar_configurations)
              end
            end
          end

          def normalize(hash)
            normalized = {
              adapter:  hash[:adapter],
              host:     hash[:host],
              port:     hash[:port],
              database: hash[:database],
              username: hash[:username],
              role:     hash[:role]
            }

            inject_makara_role!(hash, normalized)

            normalized
          end

          def inject_makara_role!(hash, normalized)
            if hash[:name].is_a?(String)
              normalized[:role] = hash[:name].split('/')[0].to_s
            end
          end
        end
      end
    end
  end
end
