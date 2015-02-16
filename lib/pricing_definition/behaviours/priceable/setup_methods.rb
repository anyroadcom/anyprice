module PricingDefinition
  module Behaviours
    module Priceable
      module SetupMethods

        ALLOWED_OPTION_KEYS = [:primary, :addon, :for, :minimum, :maximum, :currency]

        def priceable(options = {})
          @options = options
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
          validate_options!
          config.add :priceable, priceable_opts
        end

        def validate_options!
          unless (options.keys - ALLOWED_OPTION_KEYS).empty?
            raise ArgumentError, "Invalid keys for priceable"
          end
        end

        def priceable_opts
          @priceable_opts ||= {
            active_record: self, primary: true, addon: false
          }.merge(options)
        end

        def config
          PricingDefinition::Configuration
        end
      end
    end
  end
end
