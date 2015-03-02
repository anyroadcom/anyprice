class TestPriceable < ActiveRecord::Base
  include PricingDefinition::Behaviours::Priceable
  priceable currency: :currency
end

class Priceable < ActiveRecord::Base
  include PricingDefinition::Behaviours::Priceable
  self.table_name = :test_priceables
end

def create_definition!(args = {})
  PricingDefinition::Resources::Definition.create! default_price_definition_args.merge(args)
end

def build_definition(args = {})
  PricingDefinition::Resources::Definition.new default_price_definition_args.merge(args)
end

def default_price_definition_args
  {
    definition: {
      '1+' => {
        fixed: true,
        price: { fixed: 1 },
        deposit: 0
      }
    },
    priceable: TestPriceable.create!(min_limit: 1, max_limit: 20)
  }
end

class ModifierWithoutRequiredAttributes < ActiveRecord::Base
  include PricingDefinition::Behaviours::PriceableModifier
end

class ModifierWithRequiredAttributes < ActiveRecord::Base
  include PricingDefinition::Behaviours::PriceableModifier
end

class TestModifier < ActiveRecord::Base
  self.table_name = :modifier_with_required_attributes
  include PricingDefinition::Behaviours::PriceableModifier
  priceable_modifier for: :test_priceable, weight: 10, label: :label, description: :description
end

class AcmeOrder < ActiveRecord::Base
  include PricingDefinition::Behaviours::PriceableCalculator

  belongs_to :test_priceable
  belongs_to :test_modifier

  def test_addon

  end
end
