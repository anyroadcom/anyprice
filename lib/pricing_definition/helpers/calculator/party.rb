module PricingDefinition
  module Helpers
    class Calculator
      class Party < OpenStruct

        TYPE_BASE = :base
        TYPE_CHARGE = :charge

        def initialize(*args)
          @resource, @options = args[0], args[1]
          super(args[1])
        end

        [:base, :charge].each do |method_name|
          define_method("#{method_name}?") do
            type == eval("TYPE_#{method_name}".upcase)
          end
        end

        [:title, :currency].each do |attr|
          define_method(attr) do
            delegate_or_value(attr)
          end
        end

        private

        attr_reader :resource, :options

        def delegate_or_value(attr)
          options[attr].is_a?(String) ? options[attr] : resource.send(options[attr])
        end
      end
    end
  end
end

