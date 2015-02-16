require 'spec_helper'

module PricingDefinition
  describe Configuration do
    describe '.config' do
      subject { Configuration.config }

      it 'contains :modifiers and :priceables keys'do
        expect(subject).to include(:modifiers, :priceables)
      end
    end

    describe '.configure' do
      subject { Configuration.config[:variant_pricing_schemas] }

      before(:each) do
        Configuration.configure do |config|
          config.add_variant_pricing_schema "adults"
          config.add_variant_pricing_schema "adults", "seniors"
          config.add_variant_pricing_schema "adults", "children"
          config.add_variant_pricing_schema "adults", "children", "seniors"
        end
      end

      it 'wakawaka' do
        expect(subject).to include(["adults"])
        expect(subject).to include(["adults", "seniors"])
        expect(subject).to include(["adults", "children"])
        expect(subject).to include(["adults", "children", "seniors"])
      end
    end

    [:modifiers, :priceables].each do |method_name|
      describe ".#{method_name}" do
        subject { Configuration.send(method_name) }

        it 'returns an array' do
          expect(subject).to be_a(Array)
        end
      end
    end
  end
end
