require 'spec_helper'
require 'support/active_record'
require 'support/helpers'

module PricingDefinition
  module Behaviours
    module PriceableCalculator
      describe InstanceMethods do
        let(:klass) { ::AcmeOrder }
        let(:instance) { klass.new }
        let(:priceable_calculator_options) {
          {
            priceable: :test_priceable,
            priceable_addons: [:test_addon],
            priceable_modifiers: [:test_modifier],
            volume: :quantity,
            interval_start: :request_date
          }
        }

        before(:each) do
          klass.priceable_calculator(priceable_calculator_options) do |config|
            config.add_party :acme_inc, currency: "USD", name: "ACME Inc."
            config.add_party :business, currency: :business_currency, name: :business_name
            config.add_party :customer, currencsy: :customer_currency, name: :customer_name
          end
        end

        %w(priceable volume interval_start).each do |attr|
          attr_name = "pricing_#{attr}"
          describe "#{attr_name}" do
            subject { instance.send(attr_name) }

            it 'maps it to instance method' do
              instance_method = priceable_calculator_options[attr.to_sym]
              expect(subject).to eq(instance.send(instance_method))
            end
          end
        end

        describe '#priceable_calculator_party_modifiers' do
          subject { instance.priceable_calculator_party_modifiers }
          let!(:test_modifier) { TestModifier.new }

          before(:each) do
            allow(instance).to receive(:test_modifier).and_return(test_modifier)
          end

          it 'returns a hash' do
            expect(subject).to be_a(Hash)
          end

          it 'returns a hash with party names as keys' do
            party_name = subject.keys
            expect(party_name).to include(:acme_inc)
            expect(party_name).to include(:business)
            expect(party_name).to include(:customer)
          end

          it 'returns a hash with priceable modifiers as values' do
            expect(subject[:acme_inc]).to include(test_modifier.serialized)
            expect(subject[:business]).to include(test_modifier.serialized)
            expect(subject[:customer]).to include(test_modifier.serialized)
          end
        end
      end
    end
  end
end
