require 'active_record'
require 'active_support/core_ext/hash/indifferent_access'
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

      attr_reader :erroneous_ranges

      self.table_name = 'pricing_definitions'

      scope :prioritized, -> { order('weight DESC') }
      scope :deprioritized, -> { order('weight ASC') }

      serialize :definition

      belongs_to :priceable, polymorphic: true

      validates :ends_at, presence: true, if: 'starts_at.present?'
      validate :ends_at_validity, if: 'ends_at.present?'
      validate :starts_at_before_ends_at, if: 'starts_at.present?'
      validate :starts_at_validity, if: 'starts_at.present?'
      validate :definition_present
      validate :definition_schema
      validate :definition_overlapping
      validate :definition_inconsistency
      validate :definition_lowest_boundary
      validate :definition_highest_boundary

      after_initialize :set_defaults
      after_validation :normalize_errorneous_ranges

      def self.available
        predicates = []
        predicates << '(? BETWEEN starts_at AND ends_at)'
        predicates << '(starts_at IS NULL and ends_at IS NULL)'
        where(predicates.join(' OR '), Time.now)
      end

      def definition_with_ranges(cached = true)
        if cached && @definition_with_ranges
          @definition_with_ranges
        else
          @definition_with_ranges = definition.each_with_object({}) do |d, h|
            h[volume_to_range(d[0])] = d[1]
          end
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

      def pricing_collection
        definition.map do |volume, pricing|
          { "volume" => volume }.merge(pricing).with_indifferent_access
        end
      end

      def pricing_collection=(value)
        self.definition = value.each_with_object({}) do |(i, pricing), hash|
          pricing = pricing.with_indifferent_access
          hash[pricing[:volume]] = pricing
          hash[pricing[:volume]][:fixed] = !!pricing[:fixed].to_s.match(/1|true/)
          hash[pricing[:volume]].delete(:volume)
        end
      end

      private

      def set_defaults
        @erroneous_ranges = {
          inconsistent: [],
          overlapping: [],
          insufficient_lowest_boundary: [],
          insufficient_highest_boundary: []
        }
      end

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

      def definition_overlapping
        definition_ranges_combined.each do |pair|
          return if pair[1].nil?
          diff = pair[0].end - pair[1].begin

          if diff > -1 && diff != Float::INFINITY
            @erroneous_ranges[:overlapping] << pair[0].to_s
            @erroneous_ranges[:overlapping] << pair[1].to_s
            errors.add :definition, :overlapping
          end
        end
      end

      def definition_inconsistency
        definition_ranges_combined.each do |pair|
          return if pair[1].nil?
          if pair[0].end - pair[1].begin < -1
            @erroneous_ranges[:inconsistent] << pair[0].to_s
            @erroneous_ranges[:inconsistent] << pair[1].to_s
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
          @erroneous_ranges[:insufficient_lowest_boundary] << definition_sorted(:asc).first[0].try(:to_s)
          errors.add :definition, :insufficient_lowest_boundary
        end
      end

      def definition_highest_boundary
        if higher_boundary < Float::INFINITY
          @erroneous_ranges[:insufficient_highest_boundary] << definition_sorted(:desc).first[0].try(:to_s)
          errors.add :definition, :insufficient_highest_boundary
        end
      end

      def definition_schema
        definition.each do |volume, pricing|
          #errors.add :definition, :invalid_schema unless valid_schema?(pricing)
          errors.add :definition, :invalid_volume unless valid_volume?(volume)
        end
      end

      def valid_volume?(volume)
        [/\d+\+/, /\d+\.\.\d+/].any? { |rx| !volume[rx].nil? }
      end

      def valid_schema?(pricing)
        coerced_pricing = RSchema.coerce!(PRICING_SCHEMA, pricing)
        RSchema.validate!(PRICING_SCHEMA, coerced_pricing)
      rescue
        false
      end

      def priceable_config
        setup.detect { |p| p[:active_record] == priceable.class }
      end

      def setup
        PricingDefinition::Configuration.setup[:priceables]
      end

      def normalize_errorneous_ranges
        @erroneous_ranges.each do |key, ranges|
          @erroneous_ranges[key] = ranges.uniq
        end
      end
    end
  end
end
