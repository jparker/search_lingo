require 'search_lingo/parsers/open_date_range_parser'

module SearchLingo
  module Parsers
    class GTEDateParser < OpenDateRangeParser
      def initialize(*)
        warn 'DEPRECATION WARNING: use OpenDateRangeParser instead of GTEDateParser'
        super
      end
    end
  end
end
