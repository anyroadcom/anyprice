module PricingDefinition
  module Behaviours
    module Priceable
      module InstanceMethods
        def pricing_definition
          pricing_definitions.available.first
        end
      end
    end
  end
end
