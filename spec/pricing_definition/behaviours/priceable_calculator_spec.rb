require 'spec_helper'
require 'support/active_record'
require 'support/helpers'

module PricingDefinition
  module Behaviours
    describe PriceableCalculator do
      let(:klass) { ::AcmeOrder }

      context 'extending model' do
        context 'options' do
          context 'without allowed option keys' do
            subject { klass.priceable_calculator(priceable_calculator_options) { } }
            let(:priceable_calculator_options) { { some: :random, option: :config } }

            it 'raises an error' do
              expect { subject }.to raise_error
            end
          end

          context 'without required attributes' do
            subject { klass.priceable_calculator(priceable_calculator_options) { } }
            let(:priceable_calculator_options) { { priceable: :test_priceable, priceable_addons: [:test_addon], priceable_modifiers: [:test_modifier], volume: :some_quantity, interval_start: :some_request_date } }

            it 'raises an error' do
              expect(klass.attribute_names).to_not include("some_quantity")
              expect(klass.attribute_names).to_not include("some_request_date")
              expect { subject }.to raise_error
            end
          end

          context 'with allowed option keys and valid required attributes' do
            subject do
              klass.priceable_calculator(priceable_calculator_options) do |config|
                config.add_party :acme_inc, currency: "USD", name: "ACME Inc.", base: true
                config.add_party :business, currency: :currency, name: :name
              end
            end

            let(:behaviour) { PricingDefinition::Configuration.behaviour_for(klass) }
            let(:priceable_calculator_options) { { priceable: :test_priceable, priceable_addons: [:test_addon], priceable_modifiers: [:test_modifier], volume: :quantity, interval_start: :request_date } }

            it 'does not raise an error' do
              expect { subject }.to_not raise_error
            end

            it 'adds configuration for priceable calculators' do
              subject
              expect(behaviour).to eq(:priceable_calculator)
            end

            it 'associates model with PriceDefinition::Resources::Payment' do
              subject
              association = klass.reflect_on_association(:pricing_payment)
              expect(association.macro).to eq(:has_one)
              expect(association.options[:dependent]).to eq(:nullify)
              expect(association.options[:as]).to eq(:priceable_calculator)
            end

            context 'configuration block' do
              context 'when not given' do
                subject { klass.priceable_calculator(priceable_calculator_options) }

                it 'raises an error' do
                  expect { subject }.to raise_error
                end
              end

              context 'when given' do
                subject { klass.priceable_calculator(priceable_calculator_options, &config_block) }
                let(:config_block) { proc { |c| c.add_party(party_name, party_args) } }
                let(:party_name) { :acme_inc }
                let(:party_args) { { currency: "USD", name: "ACME Inc." } }

                it 'does not raise an error' do
                  expect { subject }.to_not raise_error
                end

                it 'sets up priceable calculator configuration' do
                  expect(PriceableCalculator::SetupMethods::Configure).to receive(:add_party).with(party_name, party_args)
                  subject
                end
              end
            end

            context 'delegated methods' do
              [:priceable, :volume, :interval_start].each do |attr|
                describe "#pricing_#{attr}" do
                  subject { instance.send("pricing_#{attr}".to_sym) }
                  let(:instance) { klass.new }
                  let(:instance_method) { priceable_calculator_options[attr] }

                  it 'delegates to instance method' do
                    expect(subject).to eq(instance.send(instance_method))
                  end
                end
              end
            end
          end
        end
      end
    end
  end
end
