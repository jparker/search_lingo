require 'search_lingo/parsers/mdy'

module SearchLingo
  module Parsers
    class DateParser
      include MDY

      def initialize(table, column, operator = nil)
        @table    = table
        @column   = column
        @prefix   = %r{#{operator}:\s*} if operator
      end

      attr_reader :table, :column, :prefix

      def call(token)
        token.match /\A#{prefix}(?<date>#{US_DATE})\Z/ do |m|
          date = parse m[:date]
          [:where, { table => { column => date } }] if date
        end
      end
    end
  end
end
