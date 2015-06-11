require 'search_lingo/parsers/open_date_range_parser'

module SearchLingo
  module Parsers
    class GTEDateParser < OpenDateRangeParser
      def initialize(*)
        warn "DEPRECATION WARNING: use SearchLingo::Parsers::OpenDateRangeParser " \
          "instead of #{self.class} (from #{caller.first})"
        super
      end
    end
  end
end
