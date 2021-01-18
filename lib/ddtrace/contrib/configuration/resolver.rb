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

        def add(matcher, value)
          @configurations[matcher] = value
        end

        # Matches a key with patterns keys
        # from the configuration hash.
        def resolve(key)
          @configurations[key]
        end
      end
    end
  end
end
