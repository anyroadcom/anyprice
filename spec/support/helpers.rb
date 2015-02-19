class TestPriceable < ActiveRecord::Base
  include PricingDefinition::Behaviours::Priceable
  priceable
end

class Priceable < ActiveRecord::Base
  include PricingDefinition::Behaviours::Priceable
  self.table_name = :test_priceables
end

def create_definition!(args = {})
  PricingDefinition::Resources::Definition.create! default_args.merge(args)
end

def build_definition(args = {})
  PricingDefinition::Resources::Definition.new default_args.merge(args)
end

def default_args
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
