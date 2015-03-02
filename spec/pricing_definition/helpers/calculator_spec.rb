require 'spec_helper'
require 'support/active_record'
require 'support/helpers'

module PricingDefinition
  module Helpers
    describe Calculator do
      let(:acme_order) { klass.new }
      let(:business) { double(currency: 'usd', title: 'Business Inc.') }
      let(:calculator) { PricingDefinition::Helpers::Calculator.new(acme_order) }
      let(:klass) { ::AcmeOrder }
      let(:priceable_calculator_options) { { priceable: :test_priceable, priceable_addons: [:test_addon], priceable_modifiers: [:test_modifier], volume: :quantity, interval_start: :request_date } }

      before(:each) do
        allow(acme_order).to receive(:business).and_return(business)
        klass.priceable_calculator(priceable_calculator_options) do |config|
          config.add_party :acme_inc, source: :self, currency: 'eur', type: :charge
          config.add_party :business, currency: :currency, type: :base
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
        let(:interval_start) { Date.today }

        before(:each) do
          allow(acme_order).to receive(:test_priceable).and_return(priceable)
          allow(priceable).to receive(:pricing_definition).and_return(pricing_definition)
          allow(calculator).to receive(:interval_start).and_return(interval_start)
        end

        it 'returns the pricing definition for provided interval' do
          subject
          expect(priceable).to have_received(:pricing_definition).with(interval_start)
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
          expect(subject).to eq(test_priceable)
        end
      end

      describe '#interval_start' do
        subject { calculator.interval_start }
        let(:date) { Date.new(2016, 01, 01) }

        it 'returns the associated priceable object' do
          allow(acme_order).to receive(:request_date).and_return(date)
          expect(subject).to eq(date)
        end
      end

      describe '#overall_volume' do
        subject { calculator.overall_volume }
        let(:volume) { { a: 1, b: 2, c: 3} }

        it 'returns the sum of all #volume values' do
          allow(calculator).to receive(:volume).and_return(volume)
          expect(subject).to eq(6)
        end
      end

      describe '#volume' do
        subject { calculator.volume }
        let(:volume) { { guests: 9 } }

        it 'returns resource volume' do
          allow(acme_order).to receive(:quantity).and_return(volume)
          expect(subject).to eq(volume)
        end
      end

      describe '#parties' do
        subject { calculator.parties }
        let(:acme_inc_party) { Calculator::Party.new(acme_order, name: :acme_inc, source: :self, currency: 'eur', type: :charge) }
        let(:business_party) { Calculator::Party.new(business, name: :business, type: :base, currency: :currency) }

        it 'returns the a collection of Calculator::Party instances' do
          expect(subject).to include(acme_inc_party)
          expect(subject).to include(business_party)
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
