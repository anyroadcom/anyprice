require 'spec_helper'
require 'support/active_record'
require 'support/timecop'
require 'support/helpers'

module PricingDefinition
  module Resources
    describe Definition do
      let(:definition) { Definition.new }

      describe '.available' do
        subject { Definition.available }

        let!(:default_definition) { create_definition! starts_at: nil, ends_at: nil }
        let!(:past_definition) { create_definition! starts_at: '2014-12-01', ends_at: '2014-12-21' }
        let!(:current_definition) { create_definition! starts_at: '2015-01-01', ends_at: '2015-01-31' }
        let!(:future_definition) { create_definition! starts_at: '2015-02-01', ends_at: '2015-02-28' }

        around(:each) do |example|
          Timecop.freeze Time.local(2015, 01, 15)
          example.run
          Timecop.return
        end

        it 'returns current and default definitions' do
          expect(subject).to include(default_definition)
          expect(subject).to include(current_definition)
        end

        it 'does not return past definitions' do
          expect(subject).to_not include(past_definition)
        end

        it 'does not return future definitions' do
          expect(subject).to_not include(future_definition)
        end
      end

      describe '#priceable' do
        it 'belongs to priceable as polymorphic' do
          priceable = Definition.reflect_on_association(:priceable)
          expect(priceable.macro).to eq(:belongs_to)
          expect(priceable.options[:polymorphic]).to eq(true)
        end
      end

      describe '#default?' do
        subject { definition.default? }

        context 'with interval present' do
          it 'returns false' do
            allow(definition).to receive(:interval).and_return(double('interval'))
            expect(subject).to eq(false)
          end
        end

        context 'with no interval present' do
          it 'returns true' do
            allow(definition).to receive(:interval).and_return(nil)
            expect(subject).to eq(true)
          end
        end
      end

      describe '#interval' do
        subject { definition.interval }

        let(:definition) { Definition.new starts_at: starts, ends_at: ends }

        context 'with start and end dates present' do
          let(:starts) { Date.new(2015, 01, 01) }
          let(:ends) { Date.new(2015, 01, 31) }

          it 'is a range' do
            expect(subject).to be_a(Range)
          end

          it 'begins on start date' do
            expect(subject.begin).to eq(definition.starts_at)
            expect(subject.end).to eq(definition.ends_at)
          end
        end

        context 'with start date and no end date' do
          let(:starts) { Date.new(2015, 01, 01) }
          let(:ends) { nil }

          it 'is nil' do
            expect(subject).to be_nil
          end
        end

        context 'with end date and no start date' do
          let(:starts) { nil }
          let(:ends) { Date.new(2015, 01, 01) }

          it 'is nil' do
            expect(subject).to be_nil
          end
        end
      end

      describe '#definition_with_ranges' do
        subject { definition.definition_with_ranges }

        let(:definition) { create_definition! definition: prices.inject(:update) }
        let(:prices) { [price_one_or_more, price_four_to_ten] }
        let(:pricing) { { fixed: true, price:{ fixed: 11 }, deposit: 0 } }
        let(:price_one_or_more) { { "1+" => pricing } }
        let(:price_four_to_ten) { { "4..10" => pricing } }

        it 'returns a copy of definitions with ranges as keys' do
          expect(subject.keys[0]).to be_a(Range)
          expect(subject.keys[0].to_s).to eq('1..Infinity')
          expect(subject.keys[1]).to be_a(Range)
          expect(subject.keys[1].to_s).to eq('4..10')
        end
      end

      describe '#for_volume' do
        subject { definition.for_volume(volume) }

        let(:definition) { create_definition! definition: prices.inject(:update) }
        let(:prices) { [price_one_or_more, price_four_to_ten, price_eleven_or_more] }
        let(:price_one_or_more) { { "1+" => { fixed: true, price:{ fixed: 1 }, deposit: 0 } } }
        let(:price_four_to_ten) { { "4..10" => { fixed: true, price:{ fixed: 4 }, deposit: 0 } } }
        let(:price_eleven_or_more) { { "11+" => { fixed: true, price:{ fixed: 11 }, deposit: 0 } } }

        let(:volume) { 4 }

        it 'returns first matching definition' do
          expect(subject[:volume]).to cover(volume)
          expect(subject[:volume]).to_not cover(1, 2, 3, 11)
          expect(subject[:pricing][:price][:fixed]).to eq(4)
          expect(subject[:pricing][:price][:fixed]).to_not eq(1)
          expect(subject[:pricing][:price][:fixed]).to_not eq(11)
        end
      end

      describe '#save' do
        subject { definition.save! }

        context 'validating definition' do
          let(:definition) { build_definition definition: prices.inject(:update) }

          context 'without inconsistent sequence' do
            context 'with fixed boundaries' do
              let(:prices) { [price_one_to_four, price_five_to_nine] }
              let(:pricing) { { fixed: true, price:{ fixed: 10 }, deposit: 0 } }
              let(:price_one_to_four) { { "1..4" => pricing } }
              let(:price_five_to_nine) { { "5..9" => pricing } }

              it 'does not raise an ActiveRecord::RecordInvalid error' do
                expect { subject }.to_not raise_error
              end
            end

            context 'with infinite boundaries' do
              let(:prices) { [price_one_or_more, price_five_to_nine] }
              let(:pricing) { { fixed: true, price:{ fixed: 10 }, deposit: 0 } }
              let(:price_one_or_more) { { "1+" => pricing } }
              let(:price_five_to_nine) { { "5..9" => pricing } }

              it 'does not raise an ActiveRecord::RecordInvalid error' do
                expect { subject }.to_not raise_error
              end
            end
          end

          context 'with inconsistent sequence' do
            context 'with fixed boundaries' do
              let(:prices) { [price_one_to_four, price_six_to_nine] }
              let(:pricing) { { fixed: true, price:{ fixed: 10 }, deposit: 0 } }
              let(:price_one_to_four) { { "1..4" => pricing } }
              let(:price_six_to_nine) { { "6..9" => pricing } }

              it 'raises an ActiveRecord::RecordInvalid error' do
                expect { subject }.to raise_error(ActiveRecord::RecordInvalid)
                expect(definition.errors).to include(:definition)
                expect(definition.errors[:definition][0]).to include('inconsistent')
              end
            end

            context 'with infinite boundaries' do
              let(:prices) { [price_one_to_four, price_six_or_more] }
              let(:pricing) { { fixed: true, price:{ fixed: 10 }, deposit: 0 } }
              let(:price_one_to_four) { { "1..4" => pricing } }
              let(:price_six_or_more) { { "6+" => pricing } }

              it 'raises an ActiveRecord::RecordInvalid error' do
                expect { subject }.to raise_error(ActiveRecord::RecordInvalid)
                expect(definition.errors).to include(:definition)
                expect(definition.errors[:definition][0]).to include('inconsistent')
              end
            end
          end

          context 'without overlaping volumes' do
            context 'with fixed boundaries' do
              let(:prices) { [price_one_to_four, price_four_to_six] }
              let(:pricing) { { fixed: true, price:{ fixed: 10 }, deposit: 0 } }
              let(:price_one_to_four) { { "1..4" => pricing } }
              let(:price_four_to_six) { { "5..6" => pricing } }

              it 'does not raise an ActiveRecord::RecordInvalid error' do
                expect { subject }.to_not raise_error
              end
            end

            context 'with infinite boundaries' do
              let(:prices) { [price_one_to_four, price_five_or_more] }
              let(:pricing) { { fixed: true, price:{ fixed: 10 }, deposit: 0 } }
              let(:price_one_to_four) { { "1..4" => pricing } }
              let(:price_five_or_more) { { "5+" => pricing } }

              it 'does not raise an ActiveRecord::RecordInvalid error' do
                expect { subject }.to_not raise_error
              end
            end
          end

          context 'with overlaping volumes' do
            context 'with fixed boundaries' do
              let(:prices) { [price_one_to_four, price_four_to_six] }
              let(:pricing) { { fixed: true, price:{ fixed: 10 }, deposit: 0 } }
              let(:price_one_to_four) { { "1..4" => pricing } }
              let(:price_four_to_six) { { "4..6" => pricing } }

              it 'raises an ActiveRecord::RecordInvalid error' do
                expect { subject }.to raise_error(ActiveRecord::RecordInvalid)
                expect(definition.errors).to include(:definition)
                expect(definition.errors[:definition][0]).to include('overlaping')
              end
            end

            context 'with infinite boundaries' do
              let(:prices) { [price_one_or_more, price_four_to_six] }
              let(:pricing) { { fixed: true, price:{ fixed: 10 }, deposit: 0 } }
              let(:price_one_or_more) { { "1+" => pricing } }
              let(:price_four_to_six) { { "4..6" => pricing } }

              it 'does not raise an ActiveRecord::RecordInvalid error' do
                expect { subject }.to_not raise_error
              end
            end
          end

          context 'with out of lower bounds priceable volumes' do
            let(:definition) { build_definition priceable: priceable, definition: prices.inject(:update) }
            let(:priceable) { ::TestPriceable.create! min_limit: 4, max_limit: 10, currency: :eur }

            let(:prices) { [price_one_or_more, price_four_to_six] }
            let(:pricing) { { fixed: true, price:{ fixed: 10 }, deposit: 0 } }
            let(:price_one_or_more) { { "1+" => pricing } }
            let(:price_four_to_six) { { "4..6" => pricing } }

            it 'raises an ActiveRecord::RecordInvalid error' do
              expect { subject }.to raise_error(ActiveRecord::RecordInvalid)
              expect(definition.errors).to include(:definition)
              expect(definition.errors[:definition][0]).to include('out_of_bounds_lower')
            end
          end

          context 'with out of higher bounds priceable volumes' do
            let(:definition) { build_definition priceable: priceable, definition: prices.inject(:update) }
            let(:priceable) { ::TestPriceable.create! min_limit: 1, max_limit: 8, currency: :eur }

            let(:prices) { [price_one_or_more, price_four_to_nine] }
            let(:pricing) { { fixed: true, price:{ fixed: 10 }, deposit: 0 } }
            let(:price_one_or_more) { { "1+" => pricing } }
            let(:price_four_to_nine) { { "4..9" => pricing } }

            it 'raises an ActiveRecord::RecordInvalid error' do
              expect { subject }.to raise_error(ActiveRecord::RecordInvalid)
              expect(definition.errors).to include(:definition)
              expect(definition.errors[:definition][0]).to include('out_of_bounds_higher')
            end
          end
        end

        context 'validating interval' do
          let(:definition) { build_definition }

          context 'with start date later than end date' do
            it 'raises an ActiveRecord::RecordInvalid error' do
              definition.starts_at = "2015-01-20"
              definition.ends_at = "2015-01-10"
              expect { subject }.to raise_error(ActiveRecord::RecordInvalid)
              expect(definition.errors).to include(:interval)
            end
          end

          context 'with end date earlier than start date' do
            it 'raises an ActiveRecord::RecordInvalid error' do
              definition.starts_at = "2015-01-20"
              definition.ends_at = "2015-01-10"
              expect { subject }.to raise_error(ActiveRecord::RecordInvalid)
              expect(definition.errors).to include(:interval)
            end
          end
        end
      end
    end
  end
end
