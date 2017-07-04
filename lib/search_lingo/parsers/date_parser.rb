require 'search_lingo/parsers/mdy'

module SearchLingo
  module Parsers # :nodoc:
    class DateParser
      include MDY

      def initialize(column, modifier: nil)
        @column = column
        @prefix = %r{#{modifier}:[[:space:]]*} if modifier
      end

      attr_reader :column, :prefix

      # This implementation assumes @column is an AREL Attribute.
      def call(token)
        parse_single_date(token)  ||
          parse_date_range(token) ||
          parse_lte_date(token)   ||
          parse_gte_date(token)
      end

      def inspect # :nodoc:
        '#<%s:0x%x @prefix=%s @column=%s>' %
          [self.class, object_id << 1, prefix.inspect, column.inspect]
      end

      private

      def parse_single_date(token)
        token.match /\A#{prefix}(?<date>#{US_DATE})\z/ do |m|
          date = parse(m[:date]) or return nil
          [:where, column.eq(date)]
        end
      end

      def parse_date_range(token)
        token.match /\A#{prefix}(?<min>#{US_DATE})-(?<max>#{US_DATE})\z/ do |m|
          min = parse(m[:min]) or return nil
          max = parse(m[:max], relative_to: min.next_year) or return nil
          [:where, column.in(min..max)]
        end
      end

      def parse_lte_date(token)
        token.match /\A#{prefix}-(?<date>#{US_DATE})\z/ do |m|
          date = parse(m[:date]) or return nil
          [:where, column.lteq(date)]
        end
      end

      def parse_gte_date(token)
        token.match /\A#{prefix}(?<date>#{US_DATE})-\z/ do |m|
          date = parse(m[:date]) or return nil
          [:where, column.gteq(date)]
        end
      end
    end
  end
end
