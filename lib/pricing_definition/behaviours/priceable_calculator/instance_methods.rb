module PricingDefinition
  module Behaviours
    module PriceableCalculator
      module InstanceMethods
        def calculator
          Helpers::Calculator.new(self)
        end

        def calculator_config
          @calculator_config ||= self.class.priceable_calculator_config
        end
      end
    end
  end
end
