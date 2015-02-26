module PricingDefinition
  module Behaviours
    module PriceableCalculator
      module InstanceMethods
        def priceable_calculator_party_modifiers
          self.class.pricing_party_names.each_with_object({}) do |party_name, obj|
            obj[party_name] = priceable_calculator_modifiers
          end
        end

        def priceable_calculator_modifiers
          self.class.send(:priceable_calculator_config).priceable_modifiers.map do |mod|
            self.send(mod).serialized
          end
        end
      end
    end
  end
end
