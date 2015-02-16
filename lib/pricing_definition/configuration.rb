require 'active_support/inflector'

module PricingDefinition
  class Configuration
    @@configuration  = { modifiers: [], priceables: [], variant_pricing_schemas: [] }

    def self.configure
      yield(self)
    end

    def self.config
      @@configuration.dup
    end

    def self.add(resource_type, opts = {})
      type = "#{resource_type}".pluralize
      @@configuration[type.to_sym] << opts
    end

    def self.add_variant_pricing_schema(*args)
      @@configuration[:variant_pricing_schemas] << args
    end

    class << self
      [:modifiers, :priceables].each do |config_attr|
        instance_eval do
          define_method(config_attr) do
            @@configuration[config_attr]
          end
        end
      end
    end
  end
end
