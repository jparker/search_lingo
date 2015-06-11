require 'search_lingo/parsers/open_date_range_parser'
require 'minitest_helper'

module SearchLingo::Parsers
  class TestOpenDateRangeParser < Minitest::Test
    def test_less_than_or_equal_to_MMDDYYYY
      parser = OpenDateRangeParser.new :table, :column,
        connection: dummy_connection
      assert_equal [:where, 'table.column <= ?', Date.new(2015, 6, 10)],
        parser.call('-6/10/2015')
    end

    def test_less_than_or_equal_to_MMDDYY
      parser = OpenDateRangeParser.new :table, :column,
        connection: dummy_connection
      assert_equal [:where, 'table.column <= ?', Date.new(2015, 6, 10)],
        parser.call('-6/10/15')
    end

    def test_less_than_or_equal_to_MMDD
      parser = OpenDateRangeParser.new :table, :column,
        connection: dummy_connection
      Date.stub :today, Date.new(2015, 7, 1) do
        assert_equal [:where, 'table.column <= ?', Date.new(2015, 6, 10)],
          parser.call('-6/10')
      end
    end

    def test_greater_than_or_equal_to_MMDDYYYY
      parser = OpenDateRangeParser.new :table, :column,
        connection: dummy_connection
      assert_equal [:where, 'table.column >= ?', Date.new(2015, 6, 10)],
        parser.call('6/10/2015-')
    end

    def test_greater_than_or_equal_to_MMDDYY
      parser = OpenDateRangeParser.new :table, :column,
        connection: dummy_connection
      assert_equal [:where, 'table.column >= ?', Date.new(2015, 6, 10)],
        parser.call('6/10/15-')
    end

    def test_greater_than_or_equal_to_MMDD
      parser = OpenDateRangeParser.new :table, :column,
        connection: dummy_connection
      Date.stub :today, Date.new(2015, 7, 1) do
        assert_equal [:where, 'table.column >= ?', Date.new(2015, 6, 10)],
          parser.call('6/10-')
      end
    end

    def test_table_and_column_names_are_quoted
      connection = Minitest::Mock.new
      connection.expect :quote_table_name, true, [:table]
      connection.expect :quote_column_name, true, [:column]

      parser = OpenDateRangeParser.new :table, :column, connection: connection
      parser.call('6/10-')

      connection.verify
    end

    def test_invalid_date
      parser = OpenDateRangeParser.new :table, :column,
        connection: dummy_connection
      assert_nil parser.call '32/12/2015-'
      assert_nil parser.call 'bogus-'
    end

    def test_operator
      parser = OpenDateRangeParser.new :table, :column, :operator,
        connection: dummy_connection

      assert_nil parser.call('6/10/2015-')
      assert_equal [:where, 'table.column >= ?', Date.new(2015, 6, 10)],
        parser.call('operator: 6/10/2015-')
    end

    def dummy_connection
      DummyConnection.new
    end

    class DummyConnection
      def quote_column_name(name)
        name
      end

      def quote_table_name(name)
        name
      end
    end
  end
end
