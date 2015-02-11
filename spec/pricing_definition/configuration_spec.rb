require 'spec_helper'

module PricingDefinition
  describe Configuration do
    describe '.setup' do
      subject { Configuration.setup }

      it 'contains :modifiers and :priceables keys'do
        expect(subject).to include(:modifiers, :priceables)
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
