require 'active_support/core_ext/module/delegation'
require 'pricing_definition/helpers/calculator/party'

module PricingDefinition
  module Helpers
    class Calculator
      attr_reader :resource, :parties

      delegate :calculator_config, to: :resource
      delegate :parties, :priceable_modifiers, to: :calculator_config, prefix: :config

      def initialize(resource = nil)
        @resource = resource
        setup_parties!
      end

      [:priceable, :interval_start, :volume].each do |method_name|
        define_method method_name do
          resource.send calculator_config.send(method_name)
        end
      end

      def overall_volume
        volume.map { |label, quantity| quantity }.compact.reduce(:+)
      end

      def pricing_definition
        priceable.pricing_definition(interval_start)
      end

      def base_currency
        base_party.currency
      end

      def modifiers
        config_priceable_modifiers.map do |modifier|
          resource.send(modifier)
        end.compact
      end

      def parties_modifiers
        if resource.respond_to?(:parties_modifiers)
          resource.send(:parties_modifiers)
        else
          config_parties.keys.each_with_object({}) do |party_name, obj|
            obj[party_name] = modifiers
          end
        end
      end

      private

      def setup_parties!
        config_parties.each do |name, options|
          party_options = { name: name }.merge(options)
          (@parties ||= []) << Calculator::Party.new(resource, party_options)
        end
      end
    end
  end
end
