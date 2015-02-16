require 'spec_helper'
require 'support/active_record'
require 'support/timecop'
require 'support/helpers'

module PricingDefinition
  module Resources
    describe Definition do
      let(:definition) { Definition.new }

      describe '.prioritized' do
        subject { Definition.prioritized }

        let!(:high_priority) { create_definition! starts_at: '2014-12-01', ends_at: '2014-12-21', weight: 20 }
        let!(:low_priority) { create_definition! starts_at: '2015-02-01', ends_at: '2015-02-28', weight: 10 }

        it 'returns definitions ordered by weight in descending order' do
          expect(subject[0]).to eq(high_priority)
          expect(subject[1]).to eq(low_priority)
        end
      end

      describe '.deprioritized' do
        subject { Definition.deprioritized }

        let!(:high_priority) { create_definition! starts_at: '2014-12-01', ends_at: '2014-12-21', weight: 20 }
        let!(:low_priority) { create_definition! starts_at: '2015-02-01', ends_at: '2015-02-28', weight: 10 }

        it 'returns definitions ordered by weight in ascending order' do
          expect(subject[0]).to eq(low_priority)
          expect(subject[1]).to eq(high_priority)
        end
      end

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

      describe '#pricing_collection' do
        subject { definition.pricing_collection }

        let(:definition) { create_definition! definition: prices.inject(:update) }
        let(:prices) {[
          { "1+"    => { fixed: false, price: { adult: 20, children: 10 }, deposit: 0 } },
          { "4..10" => { fixed: false, price: { adult: 40, children: 50 }, deposit: 0 } },
          { "11+"   => { fixed: false, price: { adult: 50, children: 60 }, deposit: 0 } }
        ]}

        it 'maps definition hash to an array of hashes with a :volume key' do
          expect(subject).to be_a(Array)
          expect(subject[0]).to eq({ "volume" => "1+", "fixed" => false, "price" => { "adult" => 20, "children" => 10}, "deposit" => 0 })
          expect(subject[1]).to eq({ "volume" => "4..10", "fixed" => false, "price" => { "adult" => 40, "children" => 50}, "deposit" => 0 })
          expect(subject[2]).to eq({ "volume" => "11+", "fixed" => false, "price" => { "adult" => 50, "children" => 60}, "deposit" => 0 })
        end
      end

      describe '#pricing_collection=' do
        subject { definition.definition }

        before(:each) do
          definition.pricing_collection=(collection)
        end

        let(:definition) { create_definition! }
        let(:collection) {
          {
            "0" => { "volume" => "1+"   , "fixed" => false, "price" => { "adult" => 20, "children" => 10 }, "deposit" => 0 },
            "1" => { "volume" => "4..10", "fixed" => false, "price" => { "adult" => 40, "children" => 50 }, "deposit" => 0 },
            "2" => { "volume" => "11+"  , "fixed" => false, "price" => { "adult" => 50, "children" => 60 }, "deposit" => 0 }
          }
        }

        it 'sets definition with a proper hash' do
          expect(subject).to be_a(Hash)
          expect(subject).to include("1+" => { "fixed" => false, "price" => { "adult" => 20, "children" => 10}, "deposit" => 0 })
          expect(subject).to include("4..10" => { "fixed" => false, "price" => { "adult" => 40, "children" => 50}, "deposit" => 0 })
          expect(subject).to include("11+" => { "fixed" => false, "price" => { "adult" => 50, "children" => 60}, "deposit" => 0 })
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
        let(:prices) { [price_one_or_more, price_four_to_ten, price_eleven_or_more] }
        let(:pricing) { { fixed: true, price:{ fixed: 11 }, deposit: 0 } }
        let(:price_one_or_more) { { "1+" => pricing } }
        let(:price_four_to_ten) { { "4..10" => pricing } }
        let(:price_eleven_or_more) { { "11+" => pricing } }

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

      describe '#erroneous_ranges' do
        context 'after initialization' do
          subject { Definition.new.erroneous_ranges }

          it 'returns a hash with keys' do
            expect(subject.keys).to include(:inconsistent)
            expect(subject.keys).to include(:insufficient_highest_boundary)
            expect(subject.keys).to include(:insufficient_lowest_boundary)
            expect(subject.keys).to include(:overlapping)
          end

          it 'returns a hash with empty arrays as values' do
            expect(subject.values.flatten.uniq).to eq([])
          end
        end

        context 'after validation' do
          subject { definition.erroneous_ranges }
          let(:definition) { build_definition definition: prices.inject(:update) }

          before(:each) do
            definition.valid?
          end

          context 'with valid data' do
            let(:prices) { [price_one_or_more] }
            let(:price_one_or_more) { { "1+" => { fixed: true, price:{ fixed: 1 }, deposit: 0 } } }

            it 'returns a hash with empty arrays as values' do
              expect(subject.values.flatten.uniq).to eq([])
            end
          end

          context 'with invalid data' do
            context 'with inconsistent range sequence' do
              let(:prices) { [
                { "1..2" => { fixed: true, price:{ fixed: 1 }, deposit: 0 } },
                { "6..7" => { fixed: true, price:{ fixed: 1 }, deposit: 0 } }
              ]}

              it 'sets values for the :inconsistent key' do
                expect(subject[:inconsistent]).to include('1..2')
                expect(subject[:inconsistent]).to include('6..7')
              end
            end

            context 'with overlapping ranges' do
              let(:prices) { [
                { "1..2" => { fixed: true, price:{ fixed: 1 }, deposit: 0 } },
                { "2..7" => { fixed: true, price:{ fixed: 1 }, deposit: 0 } }
              ]}

              it 'sets values for the :overlapping key' do
                expect(subject[:overlapping]).to include('1..2')
                expect(subject[:overlapping]).to include('2..7')
              end
            end

            context 'with insufficient highest boundary' do
              let(:prices) { [
                { "1..2" => { fixed: true, price:{ fixed: 1 }, deposit: 0 } },
                { "3..7" => { fixed: true, price:{ fixed: 1 }, deposit: 0 } }
              ]}

              it 'sets values for the :insufficient_highest_boundary key' do
                expect(subject[:insufficient_highest_boundary][0]).to eq('3..7')
              end
            end

            context 'with insufficient lowest boundary' do
              let(:prices) { [{ "2..3" => { fixed: true, price:{ fixed: 1 }, deposit: 0 } }] }

              it 'sets values for the :insufficient_lowest_boundary key' do
                expect(subject[:insufficient_lowest_boundary][0]).to eq('2..3')
              end
            end
          end
        end
      end

      describe '#save' do
        subject { definition.save! }

        context 'validating definition' do
          let(:definition) { build_definition definition: prices.inject(:update) }

          context 'without inconsistent sequence' do
            context 'with fixed boundaries' do
              let(:prices) { [price_one_to_four, price_five_to_nine, price_ten_or_more] }
              let(:pricing) { { fixed: true, price:{ fixed: 10 }, deposit: 0 } }
              let(:price_one_to_four) { { "1..4" => pricing } }
              let(:price_five_to_nine) { { "5..9" => pricing } }
              let(:price_ten_or_more) { { "10+" => pricing } }

              it 'does not raise an ActiveRecord::RecordInvalid error' do
                expect { subject }.to_not raise_error
              end
            end

            context 'with infinite boundaries' do
              let(:prices) { [price_one_or_more, price_five_to_nine, price_ten_or_more] }
              let(:pricing) { { fixed: true, price:{ fixed: 10 }, deposit: 0 } }
              let(:price_one_or_more) { { "1+" => pricing } }
              let(:price_five_to_nine) { { "5..9" => pricing } }
              let(:price_ten_or_more) { { "10+" => pricing } }

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

          context 'without overlapping volumes' do
            context 'with fixed boundaries' do
              let(:prices) { [price_one_to_four, price_four_to_six, price_seven_or_more] }
              let(:pricing) { { fixed: true, price:{ fixed: 10 }, deposit: 0 } }
              let(:price_one_to_four) { { "1..4" => pricing } }
              let(:price_four_to_six) { { "5..6" => pricing } }
              let(:price_seven_or_more) { { "7+" => pricing } }

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

          context 'with overlapping volumes' do
            context 'with fixed boundaries' do
              let(:prices) { [price_one_to_four, price_four_to_six] }
              let(:pricing) { { fixed: true, price:{ fixed: 10 }, deposit: 0 } }
              let(:price_one_to_four) { { "1..4" => pricing } }
              let(:price_four_to_six) { { "4..6" => pricing } }

              it 'raises an ActiveRecord::RecordInvalid error' do
                expect { subject }.to raise_error(ActiveRecord::RecordInvalid)
                expect(definition.errors).to include(:definition)
                expect(definition.errors[:definition][0]).to include('overlapping')
              end
            end

            context 'with infinite boundaries' do
              let(:prices) { [price_one_or_more, price_four_to_six, price_seven_or_more] }
              let(:pricing) { { fixed: true, price:{ fixed: 10 }, deposit: 0 } }
              let(:price_one_or_more) { { "1+" => pricing } }
              let(:price_four_to_six) { { "4..6" => pricing } }
              let(:price_seven_or_more) { { "7+" => pricing } }

              it 'does not raise an ActiveRecord::RecordInvalid error' do
                expect { subject }.to_not raise_error
              end
            end
          end

          context 'without lowest boundary' do
            let(:prices) { [price_four_to_six, price_seven_or_more] }
            let(:pricing) { { fixed: true, price:{ fixed: 10 }, deposit: 0 } }
            let(:price_four_to_six) { { "4..6" => pricing } }
            let(:price_seven_or_more) { { "7+" => pricing } }

            it 'raises an ActiveRecord::RecordInvalid error' do
              expect { subject }.to raise_error(ActiveRecord::RecordInvalid)
              expect(definition.errors).to include(:definition)
              expect(definition.errors[:definition][0]).to include('insufficient_lowest_boundary')
            end
          end

          context 'without highest boundary' do
            let(:prices) { [price_one_to_three, price_four_to_six] }
            let(:pricing) { { fixed: true, price:{ fixed: 10 }, deposit: 0 } }
            let(:price_one_to_three) { { "1..3" => pricing } }
            let(:price_four_to_six) { { "4..6" => pricing } }

            it 'raises an ActiveRecord::RecordInvalid error' do
              expect { subject }.to raise_error(ActiveRecord::RecordInvalid)
              expect(definition.errors).to include(:definition)
              expect(definition.errors[:definition][0]).to include('insufficient_highest_boundary')
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
