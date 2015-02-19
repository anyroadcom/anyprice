require 'ostruct' unless defined?(OpenStruct)
require 'active_support/inflector'

module PricingDefinition
  class Configuration
    class Setup < OpenStruct; end
    class SetupEntry < OpenStruct; end

    SUPPORTED_BEHAVIOURS = [:priceable, :priceable_modifier].freeze

    @configuration = Setup.new(
      priceable_modifiers: [],
      priceables: [],
      priceables_pricing_schemas: []
    )

    class << self
      def configure
        yield(self)
      end

      def config
        configuration.dup
      end

      def set!(behaviour, klass, opts = {})
        ensure_behaviour(behaviour) do
          add_setup_entry(behaviour, klass, opts)
        end
      end

      def add_pricing_schema(*args)
        configuration.priceables_pricing_schemas << args
      end

      def behaviour_for(resource)
        [:priceables, :priceable_modifiers].detect do |behaviour|
          if config.send(behaviour).detect { |r| r.resource == resource }
            return singularize(behaviour)
          end
        end
      end

      # TODO: make this cleaner
      def behaviour_for?(resource, behaviour)
        ensure_behaviour(behaviour, silent: true) do
          !!config.send(pluralize(behaviour)).detect { |r| r.resource == resource }
        end
      end

      private

      attr_reader :configuration

      def add_setup_entry(behaviour, klass, options)
        options = { resource: klass }.merge(options)
        behaviour = pluralize(behaviour)
        config.send(behaviour) << SetupEntry.new(options)
      end

      def ensure_behaviour(behaviour, opts = { silent: false }, &block)
        if SUPPORTED_BEHAVIOURS.include?(singularize(behaviour))
          yield(block)
        else
          opts[:silent] ? false : raise(ArgumentError)
        end
      end

      def pluralize(string)
        string.try(:to_s).pluralize.to_sym
      end

      def singularize(string)
        string.try(:to_s).singularize.to_sym
      end
    end
  end
end
