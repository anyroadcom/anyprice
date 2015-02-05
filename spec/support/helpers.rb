def default_args
  { definition: { '1+' => :price }, priceable: TestPriceable.create!(min_limit: 1, max_limit: 20) }
end

def create_definition!(args = {})
  PricingDefinition::Resources::Definition.create! default_args.merge(args)
end

def build_definition(args = {})
  PricingDefinition::Resources::Definition.new default_args.merge(args)
end

class TestPriceable < ActiveRecord::Base
  include PricingDefinition::Behaviours::Priceable
  priceable minimum: :min_limit, maximum: :max_limit, currency: :currency
end

