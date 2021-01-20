module Datadog
  module Contrib
    module Configuration
      # Resolves a configuration key to a Datadog::Contrib::Configuration:Settings object
      class Resolver
        attr_reader :configurations

        def initialize
          @configurations = {}
        end

        # Adds a new `matcher`, associating with it a `value`.
        #
        # This `value` is returned when `#resolve` is called
        # with a matching value for this matcher.
        #
        # The `matcher` can be transformed internally by the
        # `#parse_matcher` method before being stored.
        #
        # The `value` can also be retrieved by calling `#get`
        # with the same `matcher` added by this method.
        def add(matcher, value)
          @configurations[parse_matcher(matcher)] = value
        end

        # Retrieves the stored value for a `matcher`
        # previously stored by `#add`.
        def get(matcher)
          @configurations[parse_matcher(matcher)]
        end

        # Matches an arbitrary value against the configured
        # matchers previously set with `#add`.
        def resolve(value)
          @configurations[value]
        end

        protected

        # Converts `matcher` into an appropriate key
        # for the internal Hash storage.
        def parse_matcher(matcher)
          matcher
        end
      end
    end
  end
end
