require 'active_record'
require 'rschema'

module PricingDefinition
  module Resources
    class Definition < ActiveRecord::Base

      PRICING_SCHEMA = RSchema.schema do
        {
          fixed: predicate { |n| [TrueClass, FalseClass].include?(n.class) },
          price: predicate { |n|
            n.is_a?(Hash) &&
            [[:fixed], [:adults, :children]].include?(n.keys.sort) &&
            n.values.all? { |v| v.is_a?(Integer) }
          },
          deposit: Integer
        }
      end

      self.table_name = 'pricing_definitions'

      serialize :definition

      belongs_to :priceable, polymorphic: true

      validates :ends_at, presence: true, if: 'starts_at.present?'
      validate :ends_at_validity, if: 'ends_at.present?'
      validate :starts_at_before_ends_at, if: 'starts_at.present?'
      validate :starts_at_validity, if: 'starts_at.present?'
      validate :definition_present
      validate :definition_schema
      validate :definition_overlaping
      validate :definition_inconsistency
      validate :definition_lowest_boundary
      validate :definition_highest_boundary

      def self.available
        predicates = []
        predicates << '(? BETWEEN starts_at AND ends_at)'
        predicates << '(starts_at IS NULL and ends_at IS NULL)'
        where(predicates.join(' OR '), Time.now)
      end

      def definition_with_ranges
        @definition_with_ranges ||= definition.each_with_object({}) do |d, h|
          h[volume_to_range(d[0])] = d[1]
        end
      end

      def for_volume(volume = 1)
        definition_sorted(:desc).each_with_object({}).detect do |d, h|
          if d[0].cover?(volume)
            h[:volume] = d[0]
            h[:pricing] = d[1]
            return h
          else
            next
          end
        end
      end

      def default?
        interval.nil?
      end

      def interval
        if starts_at && ends_at
          starts_at..ends_at
        end
      end

      private

      def volume_to_range(vol)
        if vol.match(/\d+\+/)
          vol.to_i..Float::INFINITY
        elsif vol.match(/\d+\.\.\d+/)
          eval(vol)
        end
      end

      def definition_sorted(sort = :asc)
        sorting_order = (sort == :asc) ? 1 : -1

        sorted_definitions = definition_with_ranges.sort_by do |range, price|
          range.begin * sorting_order
        end

        Hash[*sorted_definitions.flatten]
      end

      def starts_at_before_ends_at
        if ends_at.present? && starts_at > ends_at
          errors.add :interval, :invalid
        end
      end

      def ends_at_validity
        date_validity :ends_at
      end

      def starts_at_validity
        date_validity :starts_at
      end

      def date_validity(attr)
        Date.strptime send(attr).try(:to_s), "%Y-%m-%d"
      rescue
        errors.add attr, :invalid
      end

      def lower_boundary
        definition_sorted(:asc).first[0].begin
      end

      def higher_boundary
        definition_sorted(:desc).first[0].end
      end

      def definition_ranges_combined
        ranges = definition_sorted.keys
        ranges.map!.with_index { |r,i| [r, ranges[(i + 1)]] }
      end

      def definition_overlaping
        definition_ranges_combined.each do |pair|
          return if pair[1].nil?
          diff = pair[0].end - pair[1].begin

          if diff > -1 && diff != Float::INFINITY
            errors.add :definition, :overlaping
          end
        end
      end

      def definition_inconsistency
        definition_ranges_combined.each do |pair|
          return if pair[1].nil?
          if pair[0].end - pair[1].begin < -1
            errors.add :definition, :inconsistent
          end
        end
      end

      def definition_present
        if definition.empty?
          errors.add :definition, :blank
        end
      end

      def definition_lowest_boundary
        if lower_boundary > 1
          errors.add :definition, :insufficient_lowest_boundary
        end
      end

      def definition_highest_boundary
        if higher_boundary < Float::INFINITY
          errors.add :definition, :insufficient_highest_boundary
        end
      end

      def definition_schema
        definition.each do |volume, pricing|
          errors.add :definition, :invalid_schema unless valid_schema?(pricing)
          errors.add :definition, :invalid_volume unless valid_volume?(volume)
        end
      end

      def valid_volume?(volume)
        [/\d+\+/, /\d+\.\.\d+/].any? { |rx| !volume[rx].nil? }
      end

      def valid_schema?(pricing)
        RSchema.validate!(PRICING_SCHEMA, pricing)
      rescue
        false
      end

      def priceable_config
        setup.detect { |p| p[:active_record] == priceable.class }
      end

      def setup
        PricingDefinition::Configuration.setup[:priceables]
      end
    end
  end
end
