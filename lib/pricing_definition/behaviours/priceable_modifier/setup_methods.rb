module PricingDefinition
  module Behaviours
    module PriceableModifier
      module SetupMethods

        ALLOWED_OPTION_KEYS  = [:for, :weight, :label, :description].freeze
        REQUIRED_OPTION_KEYS = [:weight, :label, :description].freeze
        REQUIRED_ATTRIBUTES  = [:fixed, :currency, :amount, :additive].freeze

        def priceable_modifier(options = {})
          @options = options.freeze
          validate_options!
          ensure_required_attributes!
          setup_config!
        end

        private

        attr_reader :options

        def setup_config!
          config.set! :priceable_modifier, self, options
        end

        def validate_options!
          ensure!("Invalid options for priceable modifier") do
            (options.keys - ALLOWED_OPTION_KEYS).empty?
          end

          ensure!("Not all required options are present") do
            (REQUIRED_OPTION_KEYS - options.keys).empty?
          end

          ensure!("Nil options are not allowed") do
            options.values.none? { |v| v.nil? }
          end
        end

        def ensure_required_attributes!
          ensure!("Not all required attributes are present") do
            REQUIRED_ATTRIBUTES.all? { |attr| attribute_names.include?(attr.to_s) }
          end
        end

        def ensure!(error_message, &block)
          unless yield(block)
            raise ArgumentError, error_message
          end
        end

        def config
          PricingDefinition::Configuration
        end
      end
    end
  end
end
