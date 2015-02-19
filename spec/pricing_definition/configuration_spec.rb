require 'spec_helper'

module PricingDefinition
  describe Configuration do
    before(:each) do
      expect(Configuration::SUPPORTED_BEHAVIOURS).to eq([:priceable, :priceable_modifier])
    end

    describe '.config' do
      subject { Configuration.config }

      it 'is a PricingDefinition::Configuration::Setup' do
        expect(subject).to be_a(PricingDefinition::Configuration::Setup)
      end

      it 'responds to #priceables and #priceable_modifiers'do
        expect(subject).to respond_to(:priceables)
        expect(subject).to respond_to(:priceable_modifiers)
      end

      it 'is immutable' do
        immutable_priceables = Configuration.config.priceables
        Configuration.config.priceables = 'mutating...'
        expect(Configuration.config.priceables).to_not eq('mutating...')
        expect(Configuration.config.priceables).to eq(immutable_priceables)
      end
    end

    describe '.set!' do
      subject { Configuration.set!(behaviour_type, klass, options) }
      let(:klass) { String }
      let(:options) { { some: :options } }

      context 'with not supported behaviour type' do
        let(:behaviour_type) { :lame_behaviour }

        it 'raises an error' do
          expect { subject }.to raise_error
        end
      end

      context 'with supported behaviour type' do
        let(:behaviour_type) { :priceable }

        it 'does not raise an error' do
          expect { subject }.to_not raise_error
        end
      end
    end

    describe '.behaviour_for' do
      subject { Configuration.behaviour_for(klass) }
      let(:config) { Configuration::Setup.new(priceables: [config_entry], priceable_modifiers: []) }
      let(:config_entry) { Configuration::SetupEntry.new(resource: String) }

      before(:each) do
        allow(Configuration).to receive(:config).and_return(config)
      end

      context 'with defined behaviour for the resource' do
        let(:klass) { String }

        it 'returns the behaviour of the resource' do
          expect(subject).to eq(:priceable)
        end
      end

      context 'without defined behaviour for the resource' do
        let(:klass) { Integer }

        it 'returns nil' do
          expect(subject).to eq(nil)
        end
      end
    end

    describe '.behaviour_for?' do
      subject { Configuration.behaviour_for?(klass, behaviour_type) }
      let(:config) { Configuration::Setup.new(priceables: [config_entry], priceable_modifiers: []) }
      let(:config_entry) { Configuration::SetupEntry.new(resource: klass) }
      let(:klass) { String }

      before(:each) do
        allow(Configuration).to receive(:config).and_return(config)
      end

      context 'with unsupported behaviour' do
        let(:behaviour_type) { :unsupported }

        it 'returns false' do
          expect(subject).to eq(false)
        end
      end

      context 'with supported behaviour' do
        context 'and behaviour defined' do
          let(:behaviour_type) { :priceable }

          it 'returns true' do
            expect(subject).to eq(true)
          end
        end

        context 'and no behaviour defined' do
          let(:behaviour_type) { :priceable_modifier }

          it 'returns false' do
            expect(subject).to eq(false)
          end
        end
      end
    end

    describe '.configure' do
      subject do
        Configuration.configure do |config|
          config.add_pricing_schema "adults"
          config.add_pricing_schema "adults", "seniors"
          config.add_pricing_schema "adults", "children"
          config.add_pricing_schema "adults", "children", "seniors"
        end
      end

      it 'wakawaka' do
        subject
        schemas = Configuration.config.priceables_pricing_schemas
        expect(schemas).to include(["adults"])
        expect(schemas).to include(["adults", "seniors"])
        expect(schemas).to include(["adults", "children"])
        expect(schemas).to include(["adults", "children", "seniors"])
      end
    end
  end
end
