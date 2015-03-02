module PricingDefinition
  module Behaviours
    module Priceable
      module InstanceMethods
        def pricing_definition(interval = nil)
          if interval.present? && !interval.is_a?(Date)
            raise ArgumentError, "interval provided must be a Date"
          else
            pricing_definitions.available(interval).prioritized.first
          end
        end

        def has_default_pricing_definition?
          !default_pricing_definitions.empty?
        end

        def default_pricing_definitions
          pricing_definitions.select(&:default?)
        end

        def default_definition
          default_pricing_definitions.try(:first)
        end
      end
    end
  end
end
