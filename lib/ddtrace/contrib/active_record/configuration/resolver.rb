require 'ddtrace/contrib/configuration/resolver'
require 'ddtrace/vendor/active_record/connection_specification'

module Datadog
  module Contrib
    module ActiveRecord
      module Configuration
        # Converts Symbols, Strings, and Hashes to a normalized connection settings Hash.
        class Resolver < Contrib::Configuration::Resolver
          def initialize(configurations = nil)
            @configurations = configurations
          end

          def resolve(key)
            normalize(key, connection_resolver.resolve(key).symbolize_keys)
          rescue => e
            Datadog.logger.error(
              "Failed to resolve ActiveRecord configuration key #{key.inspect}. " \
              "Cause: #{e.message} Source: #{e.backtrace.first}"
            )

            # Return a unique object that won't match any
            # possible hash key look up.
            Object.new
          end

          def configurations
            @configurations || ::ActiveRecord::Base.configurations
          end

          private

          # Class that allows the returned hash key
          # to partially match the desired configuration
          # with the actual database settings.
          class HashKey
            def initialize(hash)
              @hash = hash
            end

            # `#hash` is a reserved method name
            def _hash
              @hash
            end

            def eql?(other)
              other._hash.none? do |key, value|
                value != @hash[key]
              end
              # other.hash
              #
              # unless other.a.nil?
              #   return false unless other.a == a
              # end
              #
              # unless other.b.nil?
              #   return false unless other.b == b
              # end
              #
              # true
            end

            # It is not possible to crate a hash number
            # that will still allow us to match keys with
            # the flexibility we need.
            #
            # We then set all hash elements to the same value
            # to force a sequential scan of all keys.
            def hash
              0
            end

            def ==(other)
              other.is_a?(HashKey) &&
                @hash == other._hash
            end

            def to_s
              "#{self.class}:#{@hash}"
            end
          end

          def connection_resolver
            @resolver ||= begin
              if defined?(::ActiveRecord::ConnectionAdapters::ConnectionSpecification::Resolver)
                ::ActiveRecord::ConnectionAdapters::ConnectionSpecification::Resolver.new(configurations)
              else
                ::Datadog::Vendor::ActiveRecord::ConnectionAdapters::ConnectionSpecification::Resolver.new(configurations)
              end
            end
          end

          def normalize(key, hash)
            normalized = {
              adapter:  hash[:adapter],
              host:     hash[:host],
              port:     hash[:port],
              database: hash[:database],
              username: hash[:username],
              role:     hash[:role]
            }

            inject_makara_role!(key, hash, normalized)

            HashKey.new(normalized)
          end

          def inject_makara_role!(key, hash, normalized)
            # When configuring ActiveRecord with Symbols,
            # ActiveRecord injects a `name` key into it's
            # resulting hash, causing it to be mistaken
            # but a makara role.
            return if key.is_a?(Symbol)

            if hash[:name].is_a?(String)
              normalized[:role] = hash[:name].split('/')[0].to_s
            end
          end
        end
      end
    end
  end
end
