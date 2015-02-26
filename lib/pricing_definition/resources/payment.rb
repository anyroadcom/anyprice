require 'active_record'

module PricingDefinition
  module Resources
    class Payment < ActiveRecord::Base

      self.table_name = 'pricing_payments'

      belongs_to :priceable_calculator, polymorphic: true

    end
  end
end
