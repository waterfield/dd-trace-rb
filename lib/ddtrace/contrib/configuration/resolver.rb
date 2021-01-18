module Datadog
  module Contrib
    module Configuration
      # Resolves a configuration key to a Datadog::Contrib::Configuration:Settings object
      class Resolver
        attr_reader :configurations

        def initialize
          @configurations = {}
        end

        # TODO: Do we need a simple get, without fetch?
        def get(matcher)
          @configurations[matcher]
        end

        # Adds a new `matcher`, associating with it a `value`.
        # This `value` is returned when `#resolve` is called
        # with a matching value for this matcher.
        def add(matcher, value)
          @configurations[matcher] = value
        end

        # Matches an arbitrary value against the configured
        # matchers previously set with `#add`.
        def resolve(value)
          @configurations[value]
        end
      end
    end
  end
end
