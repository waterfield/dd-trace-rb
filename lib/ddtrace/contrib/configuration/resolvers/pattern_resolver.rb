require 'ddtrace/contrib/configuration/resolver'

module Datadog
  module Contrib
    module Configuration
      # Resolves a value to a configuration key
      module Resolvers
        # Matches strings against Regexps.
        class PatternResolver < Datadog::Contrib::Configuration::Resolver
          def resolve(name)
            return if configurations.empty?

            # Try to find a matching pattern
            _, config = configurations.find do |pattern, _|
              pattern === if pattern.is_a?(Proc)
                            name
                          else
                            name.to_s
                          end
            end

            # Return match or default
            config
          end

          def add(pattern, value)
            # TODO: remove? (pattern == name) # Only required during configuration time.
            pattern = pattern.to_s unless pattern.is_a?(Regexp) || pattern.is_a?(Proc)

            super(pattern, value)
          end
        end
      end
    end
  end
end
