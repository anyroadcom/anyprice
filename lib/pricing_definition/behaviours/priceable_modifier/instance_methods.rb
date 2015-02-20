require 'active_support/concern'
require 'active_model'

module PricingDefinition
  module Behaviours
    module PriceableModifier
      module InstanceMethods
        extend ActiveSupport::Concern

        included do
          include ActiveModel::Validations

          validates :currency, presence: true, if: 'fixed?'
          validates :amount, numericality: { only_integer: true, greater_than: 0 }
          validates :amount, numericality: { less_than_or_equal_to: 100 }, unless: 'fixed?'

          def serialized
            { additive: additive,
              amount: amount,
              description: priceable_modifier_description,
              label: priceable_modifier_label,
              currency: (fixed ? currency : nil),
              weight: priceable_modifier_weight
            }.with_indifferent_access
          end

          private

          def priceable_modifier_weight
            priceable_modifier_options[:weight]
          end

          def priceable_modifier_label
            string_or_delegate(priceable_modifier_options[:label])
          end

          def priceable_modifier_description
            string_or_delegate(priceable_modifier_options[:description])
          end

          def string_or_delegate(arg)
            if arg.is_a?(String)
              arg
            elsif arg.is_a?(Symbol) && respond_to?(arg)
              send(arg)
            end
          end

          def priceable_modifier_options
            self.class.send(:options)
          end
        end
      end
    end
  end
end
