# frozen-string-literal: true

require 'search_lingo/parsers/mdy'

module SearchLingo
  module Parsers # :nodoc:
    ##
    # DateParser is an example parser which handles dates that adhere to the
    # MDY format used in the US. It uses `SearchLingo::Parsers::MDY.parse` to
    # parse the date. It handles simple dates as well as closed and open-ended
    # date ranges.
    #
    # Examples of single dates are 7/14, 7/14/17, and 7/14/2017.
    # Examples of closed date ranges are 1/1-6/30 and 7/1/16-6/30/18.
    # Examples of open date ranges are -6/30 and 7/1/17-.
    class DateParser
      include MDY

      attr_reader :column, :prefix, :decorator

      def append
        warn 'DEPRECATION warning: #append has been renamed to #decorator ' \
          "(called from #{caller(1..1).first})"
        decorator
      end

      ##
      # Instantiates a new DateParser object.
      #
      # The required argument +column+ should be an Arel attribute.
      #
      # If present, the optional argument +modifier+ will be used as the
      # token operator which precedes the date term.
      #
      # If a block is provided, it will be called with the filter chain. This
      # is useful if you need to send additional messages to the filter chain
      # which are independent of the content of the token, e.g., if you need to
      # join another table.
      #
      # DateParser.new Model.arel_table[:date]
      # DateParser.new Model.arel_table[:date], modifier: 'contract'
      # DateParser.new Model.arel_table[:date] do |chain|
      #   chain.joins(:relation)
      # end
      def initialize(column, modifier: nil, &block)
        @column = column
        @prefix = /#{modifier}:[[:space:]]*/ if modifier
        @decorator = block_given? ? block : ->(chain) { chain }
      end

      ##
      # Attempts to parse +token+ as a single date, closed date range, or open
      # date range. If parsing succeeds, the parser sends #where to +chain+
      # with the appropriate Arel node and returns the result.
      def call(token, chain)
        catch :halt do
          parse_single_date token, chain
          parse_date_range  token, chain
          parse_lte_date    token, chain
          parse_gte_date    token, chain
        end
      end

      def inspect # :nodoc:
        format '#<%<cls>s @prefix=%<prefix>s @column=%<column>s>',
               cls: self.class,
               prefix: prefix.inspect,
               column: "#{column.relation.name}.#{column.name}".inspect
      end

      private

      def parse_single_date(token, chain) # :nodoc:
        token.match(/\A#{prefix}(?<date>#{US_DATE})\z/) do |m|
          date = parse(m[:date]) or return nil
          throw :halt, decorate(chain).where(column.eq(date))
        end
      end

      def parse_date_range(token, chain) # :nodoc:
        token.match(/\A#{prefix}(?<min>#{US_DATE})-(?<max>#{US_DATE})\z/) do |m|
          min = parse(m[:min]) or return nil
          max = parse(m[:max], relative_to: min.next_year) or return nil
          throw :halt, decorate(chain).where(column.in(min..max))
        end
      end

      def parse_lte_date(token, chain) # :nodoc:
        token.match(/\A#{prefix}-(?<date>#{US_DATE})\z/) do |m|
          date = parse(m[:date]) or return nil
          throw :halt, decorate(chain).where(column.lteq(date))
        end
      end

      def parse_gte_date(token, chain) # :nodoc:
        token.match(/\A#{prefix}(?<date>#{US_DATE})-\z/) do |m|
          date = parse(m[:date]) or return nil
          throw :halt, decorate(chain).where(column.gteq(date))
        end
      end

      def decorate(chain)
        decorator.call chain
      end
    end
  end
end
