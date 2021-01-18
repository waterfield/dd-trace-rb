require 'ddtrace/contrib/configuration/resolver'
require 'ddtrace/contrib/configuration/settings'

module Datadog
  module Contrib
    # Defines configurable behavior for integrations
    module Configurable
      def self.included(base)
        base.send(:include, InstanceMethods)
      end

      # Configurable instance behavior for integrations
      module InstanceMethods
        # Provides a new configuration instance for the integration.
        # This method will likely need to be overridden in each integration,
        # as their settings and defaults likely diverge from the default.
        #
        # DEV(1.0): Rename to `new_configuration`, make it protected.
        # DEV(1.0):
        # DEV(1.0): This method always provides a new instance of the configuration object for
        # DEV(1.0): the current integration, not the currently effective default configuration.
        # DEV(1.0): This is a misnomer of its function.
        # DEV(1.0):
        # DEV(1.0): Unfortunately, change this would be a breaking change for all custom integrations,
        # DEV(1.0): thus we have to be very intentional with the right time to make this change.
        # DEV(1.0): Currently marking this for a 1.0 milestone.
        def default_configuration
          Configuration::Settings.new
        end

        def reset_configuration!
          @configurations = nil # TODO: do we need this?

          @resolver = nil
          @default_configuration = nil
        end

        # Get matching configuration for key.
        # If no match, returns default configuration.
        def configuration(matcher = :default)
          return default_configuration_instance if matcher == :default

          resolver.get(matcher) || default_configuration_instance
          # configurations[configuration_key(key)]
        end

        # Get matching configuration for key.
        # If no match, returns default configuration.
        def resolve(key)
          return default_configuration_instance if key == :default

          resolver.resolve(key) || default_configuration_instance
        end

        # If the key has matching configuration explicitly defined for it,
        # then return true. Otherwise return false.
        # Note: a resolver's resolve method should not return a fallback value
        # See: https://github.com/DataDog/dd-trace-rb/issues/1204
        def configuration_for?(key)
          !resolver.resolve(key).nil? unless key == :default
        end

        def configurations
          resolver.configurations
          # @configurations ||= {
          #   :default => default_configuration_instance
          # }
        end

        # Create or update configuration with provided settings.
        def configure(matcher = :default, options = {}, &block)
          config = if matcher == :default
                     default_configuration_instance
                   else
                     # Get or add the configuration
                     resolver.get(matcher) || resolver.add(matcher, default_configuration)
                   end

          # Apply the settings
          config.configure(options, &block)
          config
        end

        protected

        # DEV(1.0): Rename to `default_configuration`, make it public.
        # DEV(1.0): See comment on `default_configuration` for more information.
        def default_configuration_instance
          @default_configuration ||= default_configuration
        end

        def resolver
          @resolver ||= Configuration::Resolver.new
        end

        # TODO: Remove these following methods?
        def add_configuration(matcher)
          resolver.add(matcher)
          config_key = resolver.resolve(matcher)
          configurations[config_key] = default_configuration_instance
        end

        def configuration_key(key)
          return :default if key.nil? || key == :default

          key = resolver.resolve(key)
          key = :default unless configurations.key?(key)
          key
        end
      end
    end
  end
end
