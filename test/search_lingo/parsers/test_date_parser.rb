require 'search_lingo/parsers/date_parser'
require 'minitest_helper'

module SearchLingo::Parsers
  class TestDateParser < Minitest::Test # :nodoc:
    def test_token_matching_MMDDYYYY
      parser = DateParser.new(:table, :column)
      expected = [:where, { table: { column: Date.new(2015, 6, 1) } }]
      assert_equal expected, parser.call('6/1/2015')
    end

    def test_token_matching_MMDDYY
      parser = DateParser.new(:table, :column)
      expected = [:where, { table: { column: Date.new(2015, 6, 1) } }]
      assert_equal expected, parser.call('6/1/15')
    end

    def test_token_matching_MMDD
      Date.stub :today, Date.new(2015, 7, 1) do
        parser = DateParser.new(:table, :column)
        expected = [:where, { table: { column: Date.new(2015, 6, 1) } }]
        assert_equal expected, parser.call('6/1')
      end
    end

    def test_token_invalid_date
      parser = DateParser.new(:table, :column)
      assert_nil parser.call '31/12/2015'
      assert_nil parser.call 'bogus'
    end

    def test_parser_defined_with_modifier
      parser = DateParser.new(:table, :column, :modifier)
      expected = [:where, { table: { column: Date.new(2015, 6, 1) } }]
      assert_equal expected, parser.call('modifier: 6/1/15')
      assert_nil parser.call '6/1/15'
    end
  end
end
