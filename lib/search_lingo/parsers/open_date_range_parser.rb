require 'search_lingo/parsers/date_parser'
require 'forwardable'

module SearchLingo
  module Parsers
    class OpenDateRangeParser < DateParser
      extend Forwardable

      DATE_RANGE = /(?:-(?<max>#{US_DATE})|(?<min>#{US_DATE})-)/

      def call(token)
        token.match /\A#{prefix}#{DATE_RANGE}\z/ do |m|
          if m[:max]
            date = parse m[:max]
            [
              :where,
              "#{quote_table_name table}.#{quote_column_name column} <= ?",
              date
            ] if date
          else
            date = parse m[:min]
            [
              :where,
              "#{quote_table_name table}.#{quote_column_name column} >= ?",
              date
            ] if date
          end
        end
      end

      def post_initialize(connection:, **)
        @connection = connection
      end

      def_delegators :@connection, :quote_column_name, :quote_table_name
    end
  end
end
