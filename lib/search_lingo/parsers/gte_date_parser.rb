require 'search_lingo/parsers/date_parser'
require 'forwardable'

module SearchLingo
  module Parsers
    class GTEDateParser < DateParser
      extend Forwardable

      def call(token)
        token.match /\A#{prefix}(?<date>#{US_DATE})-\z/ do |m|
          date = parse m[:date]
          if date
            [:where, "#{quote_table_name table}.#{quote_column_name column} >= ?", date]
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
