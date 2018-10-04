require 'search_lingo/parsers/mdy'

module SearchLingo
  module Parsers # :nodoc:
    class DateParser
      include MDY

      attr_reader :column, :prefix, :append

      ##
      # Instantiates a new DateParser object.
      #
      # The required argument +column+ should be an Arel attribute.
      #
      # If present, the optional argument +modifier+ will be used as the
      # token operator which precedes the date term.
      #
      # If a block is provided, it will be used to append additional methods to
      # the filter chain. (This is useful for static methods that must be
      # appended to the filter chain independent of the content of the token,
      # for example, if you need to join another table.)
      #
      # DateParser.new Model.arel_table[:date]
      # DateParser.new Model.arel_table[:date], modifier: 'contract'
      # DateParser.new Model.arel_table[:date] do |chain|
      #   chain.joins(:relation)
      # end
      def initialize(column, modifier: nil, &block)
        @column = column
        @prefix = %r{#{modifier}:[[:space:]]*} if modifier
        @append = if block_given?
                    block
                  else
                    ->(chain) { chain }
                  end
      end

      ##
      # Attempts to parse +token+ as a single date, closed date range, or open
      # date range. If parsing succeeds, the parser sends #where to +chain+
      # with the appropriate Arel node and returns the result.
      #
      # Dates are parsed using `SearchLingo::Parsers::MDY.parse`.
      #
      # Examples of single dates are 7/14, 7/14/17, and 7/14/2017.
      # Examples of closed date ranges are 1/1-6/30 and 7/1/16-6/30/18.
      # Examples of open date ranges are -6/30 and 7/1/17-.
      def call(token, chain)
        catch :halt do
          parse_single_date token, chain
          parse_date_range  token, chain
          parse_lte_date    token, chain
          parse_gte_date    token, chain
        end
      end

      def inspect # :nodoc:
        '#<%s:0x%x @prefix=%s @column=%s>' %
          [self.class, object_id << 1, prefix.inspect, column.inspect]
      end

      private

      def parse_single_date(token, chain) # :nodoc:
        token.match(/\A#{prefix}(?<date>#{US_DATE})\z/) do |m|
          date = parse(m[:date]) or return nil
          throw :halt, append.(chain).where(column.eq(date))
        end
      end

      def parse_date_range(token, chain) # :nodoc:
        token.match(/\A#{prefix}(?<min>#{US_DATE})-(?<max>#{US_DATE})\z/) do |m|
          min = parse(m[:min]) or return nil
          max = parse(m[:max], relative_to: min.next_year) or return nil
          throw :halt, append.(chain).where(column.in(min..max))
        end
      end

      def parse_lte_date(token, chain) # :nodoc:
        token.match(/\A#{prefix}-(?<date>#{US_DATE})\z/) do |m|
          date = parse(m[:date]) or return nil
          throw :halt, append.(chain).where(column.lteq(date))
        end
      end

      def parse_gte_date(token, chain) # :nodoc:
        token.match(/\A#{prefix}(?<date>#{US_DATE})-\z/) do |m|
          date = parse(m[:date]) or return nil
          throw :halt, append.(chain).where(column.gteq(date))
        end
      end
    end
  end
end
