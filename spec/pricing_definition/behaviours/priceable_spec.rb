require 'spec_helper'
require 'support/active_record'
require 'support/helpers'

module PricingDefinition
  module Behaviours
    describe Priceable, order: :defined do
      let(:configure_klass) { PricingDefinition::Configuration }
      let(:priceable_klass) { ::TestPriceable }

      class ::PriceableA < ActiveRecord::Base
        self.table_name = :test_priceables
        include PricingDefinition::Behaviours::Priceable
      end

      context 'priceable behaviour' do
        subject { priceable_klass.priceable(priceable_options) }

        let(:priceable_options) { { minimum: :min_limit, maximum: :max_limit, currency: :currency } }

        it 'associates priceable model with PriceDefinition::Resources::Definition' do
          subject
          association = priceable_klass.reflect_on_association(:pricing_definitions)
          expect(association.macro).to eq(:has_many)
          expect(association.options[:dependent]).to eq(:destroy)
          expect(association.options[:as]).to eq(:priceable)
        end

        it 'adds configuration for priceable' do
          subject
          priceable_config = configure_klass.priceables.detect { |ar| ar[:active_record] == priceable_klass }
          expect(priceable_config[:primary]).to eq(true)
          expect(priceable_config[:addon]).to eq(false)
          expect(priceable_config[:maximum]).to eq(:max_limit)
          expect(priceable_config[:minimum]).to eq(:min_limit)
          expect(priceable_config[:currency]).to eq(:currency)
        end
      end
    end
  end
end
