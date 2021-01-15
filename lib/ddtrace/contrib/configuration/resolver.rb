module Datadog
  module Contrib
    module Configuration
      # Resolves a configuration key to a Datadog::Contrib::Configuration:Settings object
      class Resolver
        attr_reader :configurations

        def initialize
          @configurations = {}
        end

        # TODO Do we need a simple get, without fetch?
        def get(pattern)
          @configurations[pattern]
        end

        def add(pattern, value)
          @configurations[pattern] = value
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
