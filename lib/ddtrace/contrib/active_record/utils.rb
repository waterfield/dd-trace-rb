module Datadog
  module Contrib
    module ActiveRecord
      # Common utilities for Rails
      module Utils
        EMPTY_CONFIG = {}.freeze

        def self.adapter_name
          Datadog::Utils::Database.normalize_vendor(connection_config[:adapter])
        end

        def self.database_name
          connection_config[:database]
        end

        def self.adapter_host
          connection_config[:host]
        end

        def self.adapter_port
          connection_config[:port]
        end

        # In newer Rails versions, the `payload` contains both the `connection` and its `object_id` named `connection_id`.
        #
        # So, if rails is recent we'll have a direct access to the connection.
        # Else, we'll find it thanks to the passed `connection_id`.
        #
        # See this PR for more details: https://github.com/rails/rails/pull/34602
        #
        def self.connection_config(connection = nil, connection_id = nil)
          return default_connection_config if connection.nil? && connection_id.nil?

          conn = if !connection.nil?
                   # Since Rails 6.0, the connection object
                   # is available
                   connection
                 else
                   # For Rails < 6.0, only the connection_id
                   # is available. We have to find the connection
                   # object from it.
                   begin
                     # `connection_id` is the `#object_id` of the
                     # connection. We can perform an ObjectSpace
                     # lookup to find it.
                     #
                     # This works not only for ActiveRecord, but for
                     # extensions that might have their own connection
                     # pool (e.g. https://rubygems.org/gems/makara)
                     ObjectSpace._id2ref(connection_id)
                   rescue => e
                     # Because `connection_id` references a live connection
                     # present in the current stack, it is very unlikely that
                     # `_id2ref` will fail, but we add this safeguard just
                     # in case.
                     Datadog.logger.debug(
                       "connection_id #{connection_id} does not represent a valid object. " \
                        "Cause: #{e.message} Source: #{e.backtrace.first}"
                     )
                   end
                 end

          if conn && conn.instance_variable_defined?(:@config)
            conn.instance_variable_get(:@config)
          else
            EMPTY_CONFIG
          end
        end

        # @return [Hash]
        def self.default_connection_config
          return @default_connection_config if instance_variable_defined?(:@default_connection_config)
          current_connection_name = if ::ActiveRecord::Base.respond_to?(:connection_specification_name)
                                      ::ActiveRecord::Base.connection_specification_name
                                    else
                                      ::ActiveRecord::Base
                                    end

          connection_pool = ::ActiveRecord::Base.connection_handler.retrieve_connection_pool(current_connection_name)
          connection_pool.nil? ? EMPTY_CONFIG : (@default_connection_config = db_config(connection_pool))
        rescue StandardError
          EMPTY_CONFIG
        end

        # @return [Hash]
        def self.db_config(connection_pool)
          if ::Rails::VERSION::MAJOR >= 6 && ::Rails::VERSION::MINOR >= 1
            connection_pool.db_config.configuration_hash
          else
            connection_pool.spec.config
          end
        end
      end
    end
  end
end
