require 'spec_helper'
require 'support/active_record'
require 'support/timecop'
require 'support/helpers'

module PricingDefinition
  module Behaviours
    describe Priceable do
      let(:priceable_klass) { ::TestPriceable }

      describe '#pricing_definitions' do
        subject { priceable.pricing_definitions }

        let(:priceable) { priceable_klass.create! currency: :eur, min_limit: 1, max_limit: 4 }
        let!(:high_priority) { create_definition! priceable: priceable, weight: 20 }
        let!(:low_priority) { create_definition! priceable: priceable, weight: 10 }

        it 'returns pricing definitions order by weight in descening order' do
          expect(subject[0]).to eq(high_priority)
          expect(subject[1]).to eq(low_priority)
        end
      end

      describe '#pricing_definition' do
        subject { priceable.pricing_definition }

        let(:priceable) { priceable_klass.create! currency: :eur, min_limit: 1, max_limit: 4 }
        let!(:default_definition) { create_definition! priceable: priceable, weight: 0 }

        around(:each) do |example|
          Timecop.freeze Time.local(2015, 01, 15)
          example.run
          Timecop.return
        end

        context 'with no seasonal pricing defined' do
          it 'returns the default pricing definition' do
            expect(subject).to eq(default_definition)
          end
        end

        context 'with seasonal pricing defined' do
          let!(:seasonal_definition) { create_definition! priceable: priceable, starts_at: starts, ends_at: ends, weight: 10 }

          context 'in the past' do
            let(:starts) { '2014-12-12' }
            let(:ends) { '2014-12-30' }

            it 'does not return the past pricing definition' do
              expect(subject).to_not eq(seasonal_definition)
            end
          end

          context 'in the present' do
            let(:starts) { '2015-01-01' }
            let(:ends) { '2015-01-31' }

            it 'returns the current pricing definition' do
              expect(subject).to eq(seasonal_definition)
              expect(subject).to_not eq(default_definition)
            end

            context 'that overlap' do
              let!(:prioritized) { create_definition! priceable: priceable, starts_at: starts, ends_at: ends, weight: 20 }

              it 'returns the prioritized pricing definition' do
                expect(subject).to eq(prioritized)
                expect(subject).to_not eq(seasonal_definition)
              end
            end
          end

          context 'in the future' do
            let(:starts) { '2015-02-01' }
            let(:ends) { '2015-02-28' }

            it 'does not return the future pricing definition' do
              expect(subject).to_not eq(seasonal_definition)
            end
          end
        end
      end
    end
  end
end
