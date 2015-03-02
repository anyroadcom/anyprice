require 'spec_helper'
require 'support/active_record'
require 'support/timecop'
require 'support/helpers'

module PricingDefinition
  module Behaviours
    describe Priceable do
      let(:priceable_klass) { ::TestPriceable }

      describe '#has_default_pricing_definition?' do
        subject { priceable.reload.has_default_pricing_definition? }
        let(:priceable) { priceable_klass.create! }

        context 'with default pricing definition' do
          it 'returns true' do
            create_definition! priceable: priceable, starts_at: nil, ends_at: nil
            expect(subject).to eq(true)
          end
        end

        context 'without default pricing definition' do
          it 'returns false' do
            expect(subject).to eq(false)
          end
        end
      end

      describe '#pricing_definitions' do
        subject { priceable.reload.pricing_definitions }
        let!(:priceable) { priceable_klass.create! currency: :eur, min_limit: 1, max_limit: 4 }
        let!(:high_priority) { create_definition! priceable: priceable, weight: 20, starts_at: '2015-01-01', ends_at: '2015-02-01' }
        let!(:low_priority) { create_definition! priceable: priceable, weight: 10 }

        it 'returns pricing definitions order by weight in descening order' do
          expect(subject[0]).to eq(high_priority)
          expect(subject[1]).to eq(low_priority)
        end
      end

      describe '#pricing_definition' do
        subject { priceable.pricing_definition(interval) }
        let!(:priceable) { priceable_klass.create! currency: :eur, min_limit: 1, max_limit: 4 }
        let!(:default_definition) { create_definition! priceable: priceable, weight: 0 }

        around(:each) do |example|
          Timecop.freeze Time.local(2015, 01, 15)
          example.run
          Timecop.return
        end

        context 'when interval provided is not a Date instance' do
          let(:interval) { 'some random stuff' }

          it 'raises an ArgumentError error' do
            expect { subject }.to raise_error(ArgumentError)
          end
        end

        context 'when interval provided is a Date instance' do
          let(:interval) { Date.new(2016, 01, 01) }

          context 'and season defined for that interval' do
            let!(:seasonal_definition) { create_definition!({ priceable: priceable }.merge(seasonal_options)) }
            let(:seasonal_options) { { starts_at: '2015-12-01', ends_at: '2016-01-01', weight: 100 } }

            it 'returns the matching pricing definition' do
              expect(subject).to eq(seasonal_definition)
            end
          end

          context 'and season defined for that interval' do
            it 'returns the default pricing definition' do
              expect(subject).to eq(default_definition)
            end
          end
        end

        context 'when no interval provided' do
          let(:interval) { nil }

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
end
