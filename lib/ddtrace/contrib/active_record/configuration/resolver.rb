require 'ddtrace/contrib/configuration/resolver'
require 'ddtrace/vendor/active_record/connection_specification'

module Datadog
  module Contrib
    module ActiveRecord
      module Configuration
        # Converts Symbols, Strings, and Hashes to a normalized connection settings Hash.
        #
        # When matching using a Hash, these are the valid fields:
        # ```
        # {
        #   adapter: ...,
        #   host: ...,
        #   port: ...,
        #   database: ...,
        #   username: ...,
        #   role: ...,
        # }
        # ```
        #
        # Partial matching is supported: not including certain fields or setting them to `nil`
        # will cause them to matching all values for that field. For example: `database: nil`
        # will match any database, given the remaining fields match.
        #
        # Any fields not listed above are discarded.
        #
        # When more than one configuration could be matched, the last one to match is selected,
        # based on addition order (`#add`).
        class Resolver < Contrib::Configuration::Resolver
          def initialize(ar_configurations = nil)
            super()

            @ar_configurations = ar_configurations
          end

          def ar_configurations
            @ar_configurations || ::ActiveRecord::Base.configurations
          end

          def add(matcher, value)
            resolved_pattern = connection_resolver.resolve(matcher).symbolize_keys

            normalized = normalize(resolved_pattern)

            # Remove empty fields to allow for partial matching
            normalized.reject! { |_, v| v.nil? }

            super(normalized, value)
          rescue => e
            Datadog.logger.error(
              "Failed to resolve ActiveRecord configuration key #{matcher.inspect}. " \
              "Cause: #{e.message} Source: #{e.backtrace.first}"
            )
          end

          def resolve(db_config)
            ar_config = connection_resolver.resolve(db_config).symbolize_keys

            hash = normalize(ar_config)
            inject_makara_role!(hash, ar_config)

            # Hashes in Ruby maintain insertion order
            _, config = @configurations.reverse_each.find do |matcher, _|
              matcher.none? do |key, value|
                value != hash[key]
              end
            end

            config
          rescue => e
            Datadog.logger.error(
              "Failed to resolve ActiveRecord configuration key #{db_config.inspect}. " \
              "Cause: #{e.message} Source: #{e.backtrace.first}"
            )

            nil
          end

          private

          def connection_resolver
            @resolver ||= begin
              if defined?(::ActiveRecord::ConnectionAdapters::ConnectionSpecification::Resolver)
                ::ActiveRecord::ConnectionAdapters::ConnectionSpecification::Resolver.new(ar_configurations)
              else
                ::Datadog::Vendor::ActiveRecord::ConnectionAdapters::ConnectionSpecification::Resolver.new(
                  ar_configurations
                )
              end
            end
          end

          def normalize(hash)
            {
              adapter:  hash[:adapter],
              host:     hash[:host],
              port:     hash[:port],
              database: hash[:database],
              username: hash[:username],
              role:     hash[:role]
            }
          end

          # The `makara` gem has the concept of **role**, which can be
          # inferred from the configuration `name`, in the form of:
          # `master/0`, `replica/0`, `replica/1`, etc.
          # The first part of this string is the database role.
          #
          # This allows the matching of a connection based on its role,
          # instead of connection-specific information.
          def inject_makara_role!(hash, ar_config)
            if ar_config[:name].is_a?(String)
              hash[:role] = ar_config[:name].split('/')[0].to_s
            end
          end
        end
      end
    end
  end
end
