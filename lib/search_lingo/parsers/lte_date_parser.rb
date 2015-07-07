require 'search_lingo/parsers/open_date_range_parser'

module SearchLingo
  module Parsers # :nodoc:
    class LTEDateParser < OpenDateRangeParser # :nodoc:
      def initialize(*)
        warn "DEPRECATION WARNING: use SearchLingo::Parsers::OpenDateRangeParser " \
          "instead of #{self.class} (from #{caller.first})"
        super
      end
    end
  end
end
