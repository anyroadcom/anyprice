require 'pricing_definition/behaviours/priceable_calculator/class_methods'
require 'pricing_definition/behaviours/priceable_calculator/instance_methods'
require 'pricing_definition/behaviours/priceable_calculator/setup_methods'

module PricingDefinition
  module Behaviours
    module PriceableCalculator
      def self.included(klass)
        klass.send :extend, SetupMethods
        klass.send :extend, ClassMethods
        klass.send :include, InstanceMethods
      end
    end
  end
end
