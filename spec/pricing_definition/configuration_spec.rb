require 'spec_helper'

module PricingDefinition
  describe Configuration do
    @pricing_resource_types = [:addons, :modifiers, :priceables]

    describe '.setup' do
      subject { Configuration.setup }

      it 'contains :addons, :modifiers and :priceables keys'do
        expect(subject).to include(*@pricing_resource_types)
      end
    end

    @pricing_resource_types.each do |method_name|
      describe ".#{method_name}" do
        subject { Configuration.send(method_name) }

        it 'returns an array' do
          expect(subject).to be_a(Array)
        end
      end
    end
  end
end
