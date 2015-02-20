require 'spec_helper'
require 'support/active_record'
require 'support/helpers'

module PricingDefinition
  module Behaviours
    describe PriceableModifier do
      let(:klass) { ::ModifierWithRequiredAttributes }
      let(:options) { base_options }
      let(:base_options) { { weight: 10, label: :label, description: :description } }

      before(:each) do
        klass.priceable_modifier(options)
      end

      describe '#serialized' do
        subject { instance.serialized }
        let(:instance) { klass.new }
        let(:amount) { 50 }
        let(:additive) { false }
        let(:fixed) { false }
        let(:label) { double('label') }
        let(:description) { double('description') }

        before(:each) do
          allow(instance).to receive(:additive).and_return(additive)
          allow(instance).to receive(:amount).and_return(amount)
          allow(instance).to receive(:fixed).and_return(fixed)
          allow(instance).to receive(:label).and_return(label)
          allow(instance).to receive(:description).and_return(description)
        end

        it 'contains :additive, :amount and :weight' do
          expect(subject).to include(additive: false)
          expect(subject).to include(amount: 50)
          expect(subject).to include(weight: options[:weight])
        end

        context 'with description option' do
          context 'being a string' do
            let(:options) { base_options.merge(description: description) }
            let(:description) { 'some description' }

            it 'includes the provided string' do
              expect(subject[:description]).to eq(description)
            end
          end

          context 'being a symbol' do
            let(:options) { base_options.merge(description: :description) }
            let(:description) { 'result of description method' }

            it 'includes the result of the corresponding method' do
              expect(subject[:description]).to eq(description)
            end
          end
        end

        context 'with label option' do
          context 'being a string' do
            let(:options) { base_options.merge(label: label) }
            let(:label) { 'some label' }

            it 'includes the provided string' do
              expect(subject[:label]).to eq(label)
            end
          end

          context 'being a symbol' do
            let(:options) { base_options.merge(label: :label) }
            let(:label) { 'result of label method' }

            it 'includes the result of the corresponding method' do
              expect(subject[:label]).to eq(label)
            end
          end
        end

        context 'with modifier type' do
          before(:each) do
            allow(instance).to receive(:fixed).and_return(fixed)
          end

          context 'being fixed' do
            let(:currency) { :eur }
            let(:fixed) { true }

            it 'includes currency information' do
              allow(instance).to receive(:currency).and_return(currency)
              expect(subject[:currency]).to eq(currency)
            end
          end

          context 'being non fixed' do
            let(:fixed) { false }

            it 'does not include currency information' do
              expect(subject[:currency]).to be_nil
            end
          end
        end
      end

      describe '#save' do
        subject { instance.save! }

        context 'with amount being less or equal to zero' do
          let(:instance) { klass.new amount: 0 }

          it 'raises an ActiveRecord::Invalid error' do
            expect { subject }.to raise_error(ActiveRecord::RecordInvalid)
            expect(instance.errors.keys).to include(:amount)
          end
        end

        context 'with :fixed being false' do
          let(:instance) { klass.new amount: amount, fixed: fixed }
          let(:fixed) { false }

          context 'and amount greater than 100' do
            let(:amount) { 101 }

            it 'does not raise an ActiveRecord::RecordInvalid error' do
              expect { subject }.to raise_error(ActiveRecord::RecordInvalid)
              expect(instance.errors.keys).to include(:amount)
              expect(instance.errors[:amount]).to include("must be less than or equal to 100")
            end
          end

          context 'and amount less than or equal to 100' do
            let(:amount) { 100 }

            it 'does not raise an error' do
              expect { subject }.to_not raise_error
            end
          end
        end

        context 'with :fixed being true' do
          let(:instance) { klass.new currency: currency, fixed: fixed }
          let(:fixed) { true }

          context 'and currency not present' do
            let(:currency) { nil }

            it 'raises an ActiveRecord::InvalidRecord error' do
              expect { subject }.to raise_error(ActiveRecord::RecordInvalid)
              expect(instance.errors.keys).to include(:currency)
            end
          end

          context 'and currency present' do
            let(:currency) { 'usd' }

            it 'does not raise an error' do
              expect { subject }.to_not raise_error
            end
          end
        end
      end
    end
  end
end
