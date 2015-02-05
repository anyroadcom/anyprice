require 'pricing_definition/behaviours/priceable/setup_methods'
require 'pricing_definition/behaviours/priceable/instance_methods'

module PricingDefinition
  module Behaviours
    module Priceable
      def self.included(klass)
        klass.extend SetupMethods
        klass.include InstanceMethods
      end
    end
  end
end
