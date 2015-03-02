module PricingDefinition
  module Behaviours
    module Priceable
      module SetupMethods

        ALLOWED_OPTION_KEYS = [:addon_for, :currency]

        def priceable(options = {})
          @options = options
          validate_options!
          setup_association
          setup_config!
        end

        private

        attr_reader :options

        def setup_association
          has_many :pricing_definitions, as: :priceable, class_name: 'PricingDefinition::Resources::Definition', dependent: :destroy
          accepts_nested_attributes_for :pricing_definitions, allow_destroy: true
          validates_associated :pricing_definitions
        end

        def setup_config!
          config.set! :priceable, self, options
        end

        def validate_options!
          unless (options.keys - ALLOWED_OPTION_KEYS).empty?
            raise ArgumentError, "Invalid keys for priceable"
          end
        end

        def config
          PricingDefinition::Configuration
        end
      end
    end
  end
end
