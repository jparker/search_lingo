require 'search_lingo/parsers/date_parser'

module SearchLingo
  module Parsers
    class DateRangeParser < DateParser
      def call(token)
        token.match /\A#{prefix}(?<min>#{US_DATE})-(?<max>#{US_DATE})\z/ do |m|
          min = parse m[:min]
          max = parse m[:max], relative_to: min.next_year if min
          [:where, { table => { column => min..max } }] if min && max
        end
      end
    end
  end
end
