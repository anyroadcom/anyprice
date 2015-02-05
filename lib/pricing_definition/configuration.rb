require 'ostruct' unless defined?(OpenStruct)

module PricingDefinition
  class Configuration
    @@resource_types = [
      :addons,
      :modifiers,
      :priceables
    ]

    @@configuration = {
      :addons     => [],
      :modifiers  => [],
      :priceables => []
    }

    def self.setup
      @@configuration
    end

    def self.add(resource_type, opts = {})
      type = case resource_type
             when :addon     then :addons
             when :modifier  then :modifiers
             when :priceable then :priceables
             end

      @@configuration[type] << opts
    end

    class << self
      @@resource_types.each do |config_attr|
        instance_eval do
          define_method(config_attr) do
            @@configuration[config_attr]
          end
        end
      end
    end
  end
end
