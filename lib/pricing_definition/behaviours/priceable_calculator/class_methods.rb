module PricingDefinition
  module Behaviours
    module PriceableCalculator
      module ClassMethods
        def pricing_parties
          @pricing_parties ||= priceable_calculator_config.parties
        end

        def pricing_party_names
          pricing_parties.keys
        end
      end
    end
  end
end
