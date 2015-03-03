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
      let(:test_modifier) { ::TestModifier.create! }

      before(:each) do
        allow(acme_order).to receive(:business).and_return(business)
        allow(acme_order).to receive(:test_modifier).and_return(test_modifier)
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

      describe '#serialized' do
        subject { calculator.serialized }
        let(:interval_start) { Date.parse('2015-05-01') }
        let(:volume) { { adults: 4, children: 3, seniors: 3 } }
        let(:pricing_definition) { create_definition! }
        let(:priceable) { pricing_definition.priceable }
        let(:pricing_rule) { Calculator::PricingRule.new(pricing_rule_args) }
        let(:pricing_rule_args) { { pricing: { fixed: false, price: { adults: 800, children: 600 }, deposit: 200 }, currency: :gbp } }

        before(:each) do
          allow(calculator).to receive(:interval_start).and_return(interval_start)
          allow(calculator).to receive(:volume).and_return(volume)
          allow(calculator).to receive(:priceable).and_return(priceable)
        end

        it 'includes information about the pricing' do
          allow(calculator).to receive(:pricing_rule).and_return(pricing_rule)
          pricing = subject[:pricing]
          expect(pricing[:fixed]).to eq(pricing_rule.fixed?)
          expect(pricing[:deposit]).to eq(pricing_rule.deposit)
          expect(pricing[:prices]).to eq(pricing_rule.prices)
          expect(pricing[:currency]).to eq(pricing_rule.currency)
        end

        it 'includes information about the modifiers' do
          allow(calculator).to receive(:modifiers).and_return([test_modifier])
          modifiers = subject[:modifiers]
          expect(modifiers).to include(:acme_inc, :business)
          expect(modifiers[:acme_inc]).to include(test_modifier.serialized)
          expect(modifiers[:business]).to include(test_modifier.serialized)
        end

        it 'includes information about the request' do
          request = subject[:request]
          expect(request[:interval_start]).to eq(interval_start)
          expect(request[:overall_volume]).to eq(10)
          expect(request[:volume]).to eq(volume)
          expect(request[:priceable_id]).to eq(priceable.id)
          expect(request[:priceable_type]).to eq(priceable.class.name)
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

      describe '#pricing_rule' do
        subject { calculator.pricing_rule }
        let(:pricing) { create_definition! definition: definition, priceable: priceable }
        let(:priceable) { TestPriceable.create currency: currency }
        let(:currency) { :gbp }
        let(:overall_volume) { 8 }
        let(:definition) {
          {
            '1+' => { fixed: false, price: { adults: 1000, children: 800 }, deposit: 0 },
            '2..4' => { fixed: false, price: { adults: 900, children: 700 }, deposit: 100 },
            '5..8' => { fixed: false, price: { adults: 800, children: 600 }, deposit: 200 },
            '9+' => { fixed: true, price: { fixed: 50000 }, deposit: 2000 }
          }
        }

        it 'returns rule for matching volume' do
          allow(calculator).to receive(:pricing_definition).and_return(pricing)
          allow(calculator).to receive(:overall_volume).and_return(overall_volume)
          expect(subject).to_not be_fixed
          expect(subject.prices[:adults]).to eq(Money.new(800, currency))
          expect(subject.prices[:children]).to eq(Money.new(600, currency))
          expect(subject.deposit).to eq(Money.new(200, currency))
        end
      end

      describe '#charge_currency' do
        subject { calculator.charge_currency }

        it 'returns the currency of the charge party' do
          expect(subject).to eq('eur')
        end
      end

      describe '#base_currency' do
        subject { calculator.base_currency }
        let(:business) { double(currency: currency) }
        let(:currency) { 'gbp' }

        it 'returns the currency of the base party' do
          expect(subject).to eq(currency)
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

        it 'returns a collection of all defined modifiers' do
          expect(subject).to include(test_modifier)
        end
      end

      describe '#parties_modifiers' do
        subject { calculator.parties_modifiers(serialized) }
        let(:serialized) { false }
        let(:modifiers) { { acme_inc: [test_modifier] } }

        before(:each) do
          allow(calculator).to receive(:modifiers).and_return([test_modifier])
        end

        context 'when resource does not define :parties_modifiers' do
          it 'returns its value' do
            allow(acme_order).to receive(:parties_modifiers).with(serialized).and_return(modifiers)
            expect(subject).to eq(modifiers)
          end
        end

        context 'when resource does not define :parties_modifiers' do
          context 'and serialized' do
            let(:serialized) { true }

            it 'contains parties names as keys and serialized #modifiers as values' do
              expect(calculator.resource).to_not respond_to(:parties_modifiers)
              expect(subject.keys).to include(:acme_inc, :business)
              expect(subject[:acme_inc]).to eq(calculator.modifiers.map(&:serialized))
              expect(subject[:business]).to eq(calculator.modifiers.map(&:serialized))
            end
          end

          context 'and not serialized' do
            let(:serialized) { false }

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
end
