require 'active_support/core_ext/module/delegation'

module PricingDefinition
  module Helpers
    class Calculator

      attr_reader :resource

      delegate :parties, :priceable_modifiers, to: 'resource.calculator_config'

      def initialize(resource = nil)
        @resource = resource
      end

      def priceable
        resource.send(resource.calculator_config.priceable)
      end

      def pricing_definition
        priceable.pricing_definition
      end

      def modifiers
        priceable_modifiers.map do |modifier|
          resource.send(modifier)
        end
      end

      def parties_modifiers
        if resource.respond_to?(:parties_modifiers)
          resource.send(:parties_modifiers)
        else
          parties.keys.each_with_object({}) do |party_name, obj|
            obj[party_name] = modifiers
          end
        end
      end
    end
  end
end
