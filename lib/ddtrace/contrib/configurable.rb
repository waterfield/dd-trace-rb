require 'ddtrace/contrib/configuration/resolver'
require 'ddtrace/contrib/configuration/settings'

module Datadog
  module Contrib
    # Defines configurable behavior for integrations.
    #
    # This module is responsible for coordination between
    # the configuration resolver and default configuration
    # fallback.
    module Configurable
      def self.included(base)
        base.send(:include, InstanceMethods)
      end

      # Configurable instance behavior for integrations
      module InstanceMethods
        # Provides a new configuration instance for this integration.
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

        # Resets all configuration options
        def reset_configuration!
          @resolver = nil
          @default_configuration = nil
        end

        # Get matching configuration by matcher.
        # If no match, returns the default configuration instance.
        def configuration(matcher = :default)
          return default_configuration_instance if matcher == :default

          resolver.get(matcher) || default_configuration_instance
        end

        # Resolves the matching configuration for integration-specific value.
        # If no match, returns the default configuration instance.
        def resolve(value)
          return default_configuration_instance if value == :default

          resolver.resolve(value) || default_configuration_instance
        end

        # Returns all registered configuration settings
        def configurations
          resolver.configurations.merge(default: default_configuration_instance)
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
      end
    end
  end
end
