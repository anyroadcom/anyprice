require 'spec_helper'
require 'support/active_record'
require 'support/helpers'

module PricingDefinition
  module Helpers
    class Calculator
      describe PricingRule do
        let(:pricing_rule) { PricingRule.new(pricing_for_volume) }
        let(:pricing) { create_definition! definition: definition }
        let(:pricing_for_volume) { pricing.for_volume(volume) }
        let(:volume) { 8 }
        let(:currency) { :usd }
        let(:definition) {
          {
            '1+' => { fixed: false, price: { adults: 1000, children: 800 }, deposit: 0 },
            '2..4' => { fixed: false, price: { adults: 900, children: 700 }, deposit: 100 },
            '5..8' => { fixed: false, price: { adults: 800, children: 600 }, deposit: 200 },
            '9+' => { fixed: true, price: { fixed: 50000 }, deposit: 2000 }
          }
        }

        before(:each) do
          allow(pricing.priceable).to receive(:currency).and_return(currency)
        end

        describe '#prices' do
          subject { pricing_rule.prices }

          it 'returns a hash with moenu' do
            expect(subject[:adults]).to eq(Money.new(800, currency))
            expect(subject[:children]).to eq(Money.new(600, currency))
          end
        end

        describe '#deposit' do
          subject { pricing_rule.deposit }
          let(:volume) { 20 }

          it 'returns a hash with moenu' do
            expect(subject).to eq(Money.new(2000, currency))
          end
        end

        describe '#fixed?' do
          subject { pricing_rule.fixed? }

          context 'with fixed pricing' do
            let(:volume) { 1 }

            it 'returns false' do
              expect(subject).to eq(false)
            end
          end

          context 'without fixed pricing' do
            let(:volume) { 12 }

            it 'returns true' do
              expect(subject).to eq(true)
            end
          end
        end
      end
    end
  end
end

