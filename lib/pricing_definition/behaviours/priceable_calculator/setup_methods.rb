require 'ostruct' unless defined?(OpenStruct)

module PricingDefinition
  module Behaviours
    module PriceableCalculator
      module SetupMethods

       ALLOWED_OPTION_KEYS = [:priceable, :priceable_addons, :priceable_modifiers, :interval_start, :volume]
       OPTIONS_TO_DELEGATE = [:volume, :interval_start, :priceable]

        class Configure
          @options = { parties: {} }

          class << self
            def options
              @options.dup.freeze
            end

            def add_party(party_name, opts = {})
              @options[:parties][party_name] = opts.freeze
            end
          end
        end

        def priceable_calculator(options = {}, &block)
          @priceable_calculator_options = options.freeze
          @priceable_calculator_config_block = block

          validate_options!
          validate_config_block!
          setup_config!
          setup_instance_methods

          has_one :pricing_payment, class_name: 'PricingDefinition::Resources::Payment', as: :priceable_calculator, dependent: :nullify
        end

        def validate_options!
          ensure!("Invalid options keys for priceable calculator") do
            (priceable_calculator_options.keys - ALLOWED_OPTION_KEYS).empty?
          end

          ensure!("Missing required attributes for priceable calculator") do
            OPTIONS_TO_DELEGATE.all? { |attr| self.new.respond_to?(priceable_calculator_options[attr]) }
          end

          ensure!("Priceable is not valid or is an addon for another priceable") do
            priceable_valid? && primary_priceable?
          end
        end

        def validate_config_block!
          ensure!("You need to provide a configuration block") do
            priceable_calculator_config_block.is_a?(Proc)
          end
        end

        private

        attr_reader :priceable_calculator_options, :priceable_calculator_config_block

        def setup_config!
          priceable_calculator_config_block.call(Configure)
          options = priceable_calculator_options.merge(Configure.options)
          pricing_config.set! :priceable_calculator, self, options
        end

        def setup_instance_methods
          OPTIONS_TO_DELEGATE.each do |attr|
            define_method "pricing_#{attr}" do
              send self.class.send(:priceable_calculator_options)[attr]
            end
          end
        end

        def pricing_config
          PricingDefinition::Configuration
        end

        def ensure!(error_message, &block)
          unless yield(block)
            raise ArgumentError, error_message
          end
        end

        def primary_priceable?
          priceable_config.try(:addon_for).nil?
        end

        def priceable_valid?
          pricing_config.behaviour_for(priceable_klass) == :priceable
        end

        def priceable_klass
          @priceable ||= priceable_calculator_options[:priceable].to_s.camelize.constantize
        end

        def priceable_config
          @priceable_config ||= pricing_config.get(:priceable, priceable_klass)
        end

        def priceable_calculator_config
          @priceable_calculator_config ||= pricing_config.get(:priceable_calculator, self)
        end
      end
    end
  end
end
