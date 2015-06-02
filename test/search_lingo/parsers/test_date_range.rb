require 'search_lingo/parsers/date_range_parser'
require 'minitest_helper'

module SearchLingo::Parsers
  class TestDateRangeParser < Minitest::Test
    def test_token_matching_MMDDYYYY_MMDDYYYY
      parser   = DateRangeParser.new(:table, :column)
      june1    = Date.new(2015, 6, 1)
      june30   = Date.new(2015, 6, 30)
      expected = [:where, { table: { column: june1..june30 } }]

      assert_equal expected, parser.call('6/1/2015-6/30/2015')
    end

    def test_token_matching_MMDDYY_MMDDYY
      parser   = DateRangeParser.new(:table, :column)
      june1    = Date.new(2015, 6, 1)
      june30   = Date.new(2015, 6, 30)
      expected = [:where, { table: { column: june1..june30 } }]

      assert_equal expected, parser.call('6/1/15-6/30/15')
    end

    def test_token_matching_MMDD_MMDD
      Date.stub :today, Date.new(2015, 7, 1) do
        parser   = DateRangeParser.new(:table, :column)
        june1    = Date.new(2015, 6, 1)
        august1  = Date.new(2015, 8, 1)
        expected = [:where, { table: { column: june1..august1 } }]

        assert_equal expected, parser.call('6/1-8/1')
      end
    end

    def test_token_matching_MMDDYY_MMDD
      Date.stub :today, Date.new(2015, 7, 1) do
        parser   = DateRangeParser.new(:table, :column)
        june1    = Date.new(2000, 6, 1)
        august1  = Date.new(2000, 8, 1)
        expected = [:where, { table: { column: june1..august1 } }]

        assert_equal expected, parser.call('6/1/00-8/1')
      end
    end

    def test_token_matching_MMDD_MMDDYY
      Date.stub :today, Date.new(2015, 7, 1) do
        parser   = DateRangeParser.new(:table, :column)
        june1    = Date.new(2015, 6, 1)
        august1  = Date.new(2020, 8, 1)
        expected = [:where, { table: { column: june1..august1 } }]

        assert_equal expected, parser.call('6/1-8/1/20')
      end
    end

    def test_token_invalid_date
      parser  = DateRangeParser.new(:table, :column)
      assert_nil parser.call '6/1/15-6/31/15'
      assert_nil parser.call '6/31/15-7/31/15'
    end

    def test_parser_defined_with_operator
      parser   = DateRangeParser.new(:table, :column, :operator)
      june1    = Date.new(2015, 6, 1)
      june30   = Date.new(2015, 6, 30)
      expected = [:where, { table: { column: june1..june30 } }]

      assert_equal expected, parser.call('operator: 6/1/15-6/30/15')
      assert_nil parser.call '6/1/15-6/30/15'
    end
  end
end
