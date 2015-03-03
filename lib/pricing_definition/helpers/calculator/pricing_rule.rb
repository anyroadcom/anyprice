require 'money'

module PricingDefinition
  module Helpers
    class Calculator
      class PricingRule
        def initialize(rule = {})
          @rule = rule
        end

        def fixed?
          rule[:pricing][:fixed] == true
        end

        def deposit
          @deposit ||= Money.new(pricing.deposit, currency)
        end

        def prices
          @prices ||= pricing.price.each_with_object({}) do |pair, obj|
            obj[pair[0]] = Money.new(pair[1], currency)
          end
        end

        def currency
          @currency ||= rule[:currency]
        end

        private

        attr_reader :rule

        def pricing
          @pricing ||= OpenStruct.new(rule[:pricing])
        end
      end
    end
  end
end

