require 'spec_helper'
require 'support/active_record'
require 'support/helpers'

module PricingDefinition
  module Behaviours
    describe PriceableModifier do
      subject { klass.priceable_modifier(options) }
      let(:klass) { ::ModifierWithRequiredAttributes }

      context 'priceable modifier behaviour declaration' do
        context 'with invalid option keys' do
          let(:options) { { unsupported: :configuration } }

          it 'raises an error' do
            expect { subject }.to raise_error
          end
        end

        context 'with valid option keys' do
          let(:behaviour) { PricingDefinition::Configuration.behaviour_for(klass) }
          let(:options) { { for: :priceable, label: 'Discount', description: 'Free beer!', weight: 10 } }

          it 'does not raise an error' do
            expect { subject }.to_not raise_error
          end

          it 'adds update configuration for priceable modifiers' do
            subject
            expect(behaviour).to eq(:priceable_modifier)
          end
        end
      end

      context 'host model validation' do
        subject { klass.priceable_modifier(options) }
        let(:options) { { label: 'Discount', description: 'Free beer!', weight: 10 } }

        context 'with required defined attributed' do
          let(:klass) { ::ModifierWithRequiredAttributes }

          it 'does not raise an error' do
            expect { subject }.to_not raise_error
          end
        end

        context 'with required defined attributed' do
          let(:klass) { ::ModifierWithoutRequiredAttributes }

          it 'raises an error' do
            expect { subject }.to raise_error
          end
        end
      end
    end
  end
end
