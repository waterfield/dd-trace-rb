require 'ddtrace/contrib/configuration/resolver'

module Datadog
  module Contrib
    module Configuration
      # Resolves a value to a configuration key
      module Resolvers
        # Matches strings against Regexps.
        class PatternResolver < Contrib::Configuration::Resolver
          def resolve(name)
            return if configurations.empty?

            # Try to find a matching pattern
            _, config = configurations.find do |matcher, _|
              matcher === if matcher.is_a?(Proc)
                            name
                          else
                            name.to_s
                          end
            end

            # Return match or default
            config
          end

          protected

          def parse_matcher(matcher)
            if matcher.is_a?(Regexp) || matcher.is_a?(Proc)
              matcher
            else
              matcher.to_s
            end
          end
        end
      end
    end
  end
end
