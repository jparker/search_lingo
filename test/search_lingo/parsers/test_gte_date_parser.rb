require 'search_lingo/parsers/gte_date_parser'
require 'minitest_helper'

module SearchLingo::Parsers
  class TestGTEDateParser < Minitest::Test
    def test_token_matching_MDDYYYY
      parser   = GTEDateParser.new :table, :column, connection: dummy_connection
      expected = [:where, '"table"."column" >= ?', Date.new(2015, 6, 1)]
      assert_equal expected, parser.call('6/1/2015-')
    end

    def test_token_matching_MMDDYY
      parser   = GTEDateParser.new :table, :column, connection: dummy_connection
      expected = [:where, '"table"."column" >= ?', Date.new(2015, 6, 1)]
      assert_equal expected, parser.call('6/1/15-')
    end

    def test_token_matching_MMDD
      Date.stub :today, Date.new(2015, 7, 1) do
        parser   = GTEDateParser.new :table, :column, connection: dummy_connection
        expected = [:where, '"table"."column" >= ?', Date.new(2015, 6, 1)]
        assert_equal expected, parser.call('6/1-')
      end
    end

    def test_token_invalid_date
      parser = GTEDateParser.new :table, :column, connection: dummy_connection
      assert_nil parser.call '31/12/2015-'
      assert_nil parser.call 'bogus-'
    end

    def test_parser_defined_with_operator
      parser = GTEDateParser.new :table, :column, :operator, connection: dummy_connection
      expected = [:where, '"table"."column" >= ?', Date.new(2015, 6, 1)]
      assert_equal expected, parser.call('operator: 6/1/15-')
      assert_nil parser.call '-6/1/15'
    end
  end
end