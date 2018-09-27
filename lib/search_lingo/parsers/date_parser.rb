require 'search_lingo/parsers/mdy'

module SearchLingo
  module Parsers # :nodoc:
    class DateParser
      include MDY

      ##
      # Instantiates a new DateParser object.
      #
      # The required argument +column+ should be an Arel attribute.
      #
      # If present, the optional argument +modifier+ will be used as the
      # operator which precedes the date term.
      #
      # DateParser.new Booking.arel_table[:date]
      # DateParser.new Contract.arel_table[:date], modifier: 'contract'
      def initialize(column, modifier: nil)
        @column = column
        @prefix = %r{#{modifier}:[[:space:]]*} if modifier
      end

      attr_reader :column, :prefix

      ##
      # Attempts to parse the token as a date, closed date range, or open date
      # range.
      #
      # Examples of single dates are 7/14, 7/14/17, and 7/14/2017.
      # Examples of closed date ranges are 1/1-6/30 and 7/1/16-6/30/18.
      # Examples of open date ranges are -6/30 and 7/1/17-.
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
