require 'spec_helper'
require 'support/active_record'
require 'support/helpers'

module PricingDefinition
  module Helpers
    describe Calculator do
      let(:calculator) { PricingDefinition::Helpers::Calculator.new(acme_order) }
      let(:acme_order) { ::AcmeOrder.new }
      let(:priceable_calculator_options) { { priceable: :test_priceable, priceable_addons: [:test_addon], priceable_modifiers: [:test_modifier], volume: :quantity, interval_start: :request_date } }

      before(:each) do
        ::AcmeOrder.priceable_calculator(priceable_calculator_options) do |config|
          config.add_party :acme_inc, currency: "USD", name: "ACME Inc.", base: true
          config.add_party :business, currency: :currency, name: :name
        end
      end

      describe '#resource' do
        subject { calculator.resource }

        it 'returns the object with which it was initialized' do
          expect(subject).to eq(acme_order)
        end
      end

      describe '#pricing_definition' do
        subject { calculator.pricing_definition }
        let(:pricing_definition) { create_definition! }
        let(:priceable) { pricing_definition.priceable }

        before(:each) do
          allow(acme_order).to receive(:test_priceable).and_return(priceable)
          allow(priceable).to receive(:pricing_definition).and_return(pricing_definition)
        end

        it 'returns the pricing definition for priceable' do
          expect(subject).to eq(pricing_definition)
        end
      end

      describe '#priceable' do
        subject { calculator.priceable }
        let(:test_priceable) { ::TestPriceable.new }

        it 'returns the associated priceable object' do
          allow(acme_order).to receive(:test_priceable).and_return(test_priceable)
          expect(subject).to eq(acme_order.test_priceable)
        end
      end

      describe '#parties' do
        subject { calculator.parties }

        it 'returns the partires with their configuration' do
          expect(subject[:acme_inc]).to include(currency: "USD", name: "ACME Inc.", base: true)
          expect(subject[:business]).to include(currency: :currency, name: :name)
        end
      end

      describe '#modifiers' do
        subject { calculator.modifiers }
        let!(:test_modifier) { ::TestModifier.new }

        before(:each) do
          allow(acme_order).to receive(:test_modifier).and_return(test_modifier)
        end

        it 'returns a collection of all defined modifiers' do
          expect(subject).to include(test_modifier)
        end
      end

      describe '#parties_modifiers' do
        subject { calculator.parties_modifiers }
        let!(:modifier) { ::TestModifier.new }

        before(:each) do
          allow(calculator).to receive(:modifiers).and_return([modifier])
        end

        context 'when resource does not define :parties_modifiers' do
          it 'returns its value' do
            modifiers = { acme_inc: [modifier] }
            allow(acme_order).to receive(:parties_modifiers).and_return(modifiers)
            expect(acme_order).to respond_to(:parties_modifiers)
            expect(subject).to eq(modifiers)
          end
        end

        context 'when resource does not define :parties_modifiers' do
          it 'contains parties names as keys and #modifiers as values' do
            expect(calculator.resource).to_not respond_to(:parties_modifiers)
            expect(subject.keys).to include(:acme_inc, :business)
            expect(subject[:acme_inc]).to eq(calculator.modifiers)
            expect(subject[:business]).to eq(calculator.modifiers)
          end
        end
      end
    end
  end
end
