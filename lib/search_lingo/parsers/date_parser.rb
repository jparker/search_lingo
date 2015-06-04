require 'search_lingo/parsers/mdy'

module SearchLingo
  module Parsers
    class DateParser
      include MDY

      def initialize(table, column, operator = nil, **options)
        @table    = table
        @column   = column
        @prefix   = %r{#{operator}:\s*} if operator

        post_initialize **options
      end

      attr_reader :table, :column, :prefix

      def call(token)
        token.match /\A#{prefix}(?<date>#{US_DATE})\Z/ do |m|
          date = parse m[:date]
          [:where, { table => { column => date } }] if date
        end
      end

      def post_initialize(**)
      end

      def inspect
        '#<%s:0x%x @table=%s @column=%s @prefix=%s>' %
          [self.class, object_id << 1, table, column, prefix]
      end
    end
  end
end
