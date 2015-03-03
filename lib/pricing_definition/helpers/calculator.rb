require 'active_support/core_ext/module/delegation'
require "pricing_definition/helpers/calculator/party"
require "pricing_definition/helpers/calculator/pricing_rule"

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

      # Define delegator methods for @resource attributes
      [:priceable, :interval_start, :volume].each do |method_name|
        define_method method_name do
          resource.send calculator_config.send(method_name)
        end
      end

      [:base, :charge].each do |attr|
        define_method("#{attr}_party") do
          parties.detect { |p| p.send("#{attr}?") }
        end

        define_method("#{attr}_currency") do
          send("#{attr}_party").try(:currency)
        end
      end

      def serialized
        {
          pricing: {
            fixed: pricing_rule.fixed?,
            deposit: pricing_rule.deposit,
            currency: pricing_rule.currency,
            prices: pricing_rule.prices
          },
          request: {
            interval_start: interval_start,
            overall_volume: overall_volume,
            volume: volume,
            priceable_type: priceable.class.name,
            priceable_id: priceable.id
          },
          modifiers: parties_modifiers(true)
        }
      end

      def overall_volume
        volume.map { |label, quantity| quantity }.compact.reduce(:+)
      end

      def pricing_definition
        priceable.pricing_definition(interval_start)
      end

      def pricing_rule
        Calculator::PricingRule.new(pricing_definition.for_volume(overall_volume))
      end

      def modifiers
        (config_priceable_modifiers || []).map do |modifier|
          resource.send(modifier)
        end.compact
      end

      def parties_modifiers(serialized = false)
        if resource.respond_to?(:parties_modifiers)
          resource.send(:parties_modifiers, serialized)
        else
          config_parties.keys.each_with_object({}) do |party_name, obj|
            obj[party_name] = serialized ? modifiers.map(&:serialized) : modifiers
          end
        end
      end

      private

      def setup_parties!
        config_parties.each do |name, options|
          party_options = { name: name }.merge(options)
          party_objects = party_resource(name, options[:source])
          (@parties ||= []) << Calculator::Party.new(party_objects, party_options)
        end
      end

      def party_resource(name, source)
        case source
        when :self then resource
        when nil then resource.send(name)
        else resource.send(source)
        end
      end
    end
  end
end
