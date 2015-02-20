require 'pricing_definition/behaviours/priceable_modifier/setup_methods'
require 'pricing_definition/behaviours/priceable_modifier/instance_methods'

module PricingDefinition
  module Behaviours
    module PriceableModifier
      def self.included(klass)
        klass.extend SetupMethods
        klass.include InstanceMethods
      end
    end
  end
end
