require 'spec_helper'
require 'support/active_record'
require 'support/helpers'

module PricingDefinition
  module Behaviours
    describe Priceable, order: :defined do
      let(:config_klass) { PricingDefinition::Configuration }
      let(:priceable_klass) { ::Priceable }

      before(:each) do
      end

      context 'priceable behaviour' do
        subject { priceable_klass.priceable(priceable_options) }
        let(:priceable_options) { {} }

        it 'associates priceable model with PriceDefinition::Resources::Definition' do
          subject
          association = priceable_klass.reflect_on_association(:pricing_definitions)
          expect(association.macro).to eq(:has_many)
          expect(association.options[:dependent]).to eq(:destroy)
          expect(association.options[:as]).to eq(:priceable)
        end

        context 'with invalid option keys' do
          let(:priceable_options) { { invalid: :option } }

          it 'adds configuration for priceable' do
            expect { subject }.to raise_error(ArgumentError)
          end
        end

        context 'with valid option keys' do
          let(:priceable_options) { { addon_for: :a_model } }

          it 'marks host class as priceable' do
            subject
            expect(config_klass.behaviour_for(priceable_klass)).to eq(:priceable)
          end
        end
      end
    end
  end
end
