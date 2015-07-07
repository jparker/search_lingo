require 'search_lingo/parsers/gte_date_parser'
require 'minitest_helper'

module SearchLingo::Parsers
  class TestGTEDateParser < Minitest::Test # :nodoc:
    def test_inherits_from_open_date_range_parser
      assert_includes LTEDateParser.ancestors, OpenDateRangeParser
    end
  end
end
