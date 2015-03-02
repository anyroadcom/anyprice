require 'spec_helper'
require 'support/active_record'
require 'support/helpers'

module PricingDefinition
  module Helpers
    class Calculator
      describe Party do
        let(:party) { Party.new(resource, options) }
        let(:resource) { ::AcmeOrder.new }
        let(:options) { { name: :acme_inc, title: title, currency: currency, type: type } }
        let(:title) { "ACME Inc." }
        let(:currency) { "USD" }
        let(:type) { :charge }

        [:charge, :base].each do |method|
          describe "##{method}?" do
            subject { party.send("#{method}?") }

            context "with #{method} type" do
              let(:type) { method }
              it 'returns true' do
                expect(subject).to eq(true)
              end
            end

            context "without :#{method} type" do
              let(:type) { "random" }
              it 'returns false' do
                expect(subject).to eq(false)
              end
            end
          end
        end

        [:currency, :title].each do |attr|
          describe "##{attr}" do
            subject { party.send(attr) }

            context "with string for :#{attr} value" do
              let(attr) { "some string" }
              it "returns string provided"do
                expect(subject).to eq("some string")
              end
            end

            context "with symbol for :#{attr} value" do
              let(attr) { :some_method }
              context "and resource responds to method" do
                it "returns the result of the method"do
                  allow(resource).to receive(send(attr)).and_return("EUR")
                  expect(subject).to eq("EUR")
                end
              end

              context "and resource does not respond to method" do
                it "returns the result of the method"do
                  expect { subject }.to raise_error
                end
              end
            end
          end
        end
      end
    end
  end
end
