require 'search_lingo/parsers/open_date_range_parser'

module SearchLingo
  module Parsers
    class LTEDateParser < OpenDateRangeParser
      def initialize(*)
        warn "DEPRECATION WARNING: use OpenDateRangeParser instead of GTEDateParser (from #{caller.first})"
        super
      end
    end
  end
end
