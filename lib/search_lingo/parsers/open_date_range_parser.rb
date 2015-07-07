require 'search_lingo/parsers/date_parser'
require 'forwardable'

module SearchLingo
  module Parsers # :nodoc:
    class OpenDateRangeParser < DateParser
      extend Forwardable

      def call(token)
        parse_lte(token) || parse_gte(token)
      end

      def post_initialize(connection:, **)
        @connection = connection
      end

      def_delegators :@connection, :quote_column_name, :quote_table_name

      private

      def parse_lte(token) # :nodoc:
        token.match /\A#{prefix}-(?<date>#{US_DATE})\z/ do |m|
          if date = parse(m[:date])
            [
              :where,
              "#{quote_table_name table}.#{quote_column_name column} <= ?",
              date
            ]
          end
        end
      end

      def parse_gte(token) # :nodoc:
        token.match /\A#{prefix}(?<date>#{US_DATE})-\z/ do |m|
          if date = parse(m[:date])
            [
              :where,
              "#{quote_table_name table}.#{quote_column_name column} >= ?",
              date
            ]
          end
        end
      end
    end
  end
end
