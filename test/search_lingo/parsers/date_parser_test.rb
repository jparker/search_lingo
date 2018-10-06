# frozen-string-literal: true

require 'search_lingo/parsers/date_parser'
require 'minitest_helper'

module SearchLingo
  module Parsers
    # rubocop:disable Metrics/ClassLength
    class DateParserTest < Minitest::Test # :nodoc:
      def test_mmddyyyy
        column = mock('column')
        column.expects(:eq).with(Date.new(2017, 7, 4))
        parser = DateParser.new column
        parser.call '7/4/2017', mock(where: nil)
      end

      def test_mmddyy
        column = mock('column')
        column.expects(:eq).with(Date.new(2017, 7, 4))
        parser = DateParser.new column
        parser.call '7/4/17', mock(where: nil)
      end

      def test_mmdd
        column = mock('column')
        column.expects(:eq).with(Date.new(1776, 7, 4))
        Date.stub :today, Date.new(1776, 12, 25) do
          parser = DateParser.new column
          parser.call '7/4', mock(where: nil)
        end
      end

      def test_mmddyyyy_mmddyyyy
        column = mock('column')
        column.expects(:in).with(Date.new(2017)..Date.new(2017, 6, 30))
        parser = DateParser.new column
        parser.call '1/1/2017-6/30/2017', mock(where: nil)
      end

      def test_mmddyy_mmddyy
        column = mock('column')
        column.expects(:in).with(Date.new(2017)..Date.new(2017, 6, 30))
        parser = DateParser.new column
        parser.call '1/1/17-6/30/17', mock(where: nil)
      end

      def test_mmdd_mmdd
        column = mock('column')
        column.expects(:in).with(Date.new(1776, 7)..Date.new(1776, 7, 31))
        Date.stub :today, Date.new(1776, 7, 4) do
          parser = DateParser.new column
          parser.call '7/1-7/31', mock(where: nil)
        end
      end

      def test_mmddyy_mmdd
        column = mock('column')
        column.expects(:in).with(Date.new(2017, 7)..Date.new(2017, 7, 31))
        Date.stub :today, Date.new(1776, 7, 4) do
          parser = DateParser.new column
          parser.call '7/1/17-7/31', mock(where: nil)
        end
      end

      def test_mmdd_mmddyy
        column = mock('column')
        column.expects(:in).with(Date.new(1776, 7)..Date.new(2017, 7, 31))
        Date.stub :today, Date.new(1776, 7, 4) do
          parser = DateParser.new column
          parser.call '7/1-7/31/17', mock(where: nil)
        end
      end

      def test_less_than_mmddyyyy
        column = mock('column')
        column.expects(:lteq).with(Date.new(2017, 7, 1))
        parser = DateParser.new column
        parser.call '-7/1/2017', mock(where: nil)
      end

      def test_less_than_mmddyy
        column = mock('column')
        column.expects(:lteq).with(Date.new(2017, 7, 1))
        parser = DateParser.new column
        parser.call '-7/1/17', mock(where: nil)
      end

      def test_less_than_mmdd
        column = mock('column')
        column.expects(:lteq).with(Date.new(1776, 7, 1))
        Date.stub :today, Date.new(1776, 7, 4) do
          parser = DateParser.new column
          parser.call '-7/1', mock(where: nil)
        end
      end

      def test_greater_than_mmddyyyy
        column = mock('column')
        column.expects(:gteq).with(Date.new(2017, 7, 1))
        parser = DateParser.new column
        parser.call '7/1/2017-', mock(where: nil)
      end

      def test_greater_than_mmddyy
        column = mock('column')
        column.expects(:gteq).with(Date.new(2017, 7, 1))
        parser = DateParser.new column
        parser.call '7/1/17-', mock(where: nil)
      end

      def test_greater_than_mmdd
        column = mock('column')
        column.expects(:gteq).with(Date.new(1776, 7, 1))
        Date.stub :today, Date.new(1776, 7, 4) do
          parser = DateParser.new column
          parser.call '7/1-', mock(where: nil)
        end
      end

      def test_invalid_date
        scope = stub(where: 'blerg')
        column = mock('column')
        column.expects(:eq).with(Date.new(2016, 2, 29))
        parser = DateParser.new column
        refute_nil parser.call '2/29/2016', scope
        assert_nil parser.call '2/29/2017', scope
        assert_nil parser.call 'bogus', scope
      end

      def test_invalid_date_range
        scope = stub(where: 'blerg')
        column = stub('column')
        parser = DateParser.new column
        assert_nil parser.call '7/1/2017-7/32/2017', scope
        assert_nil parser.call '-7/32/2017', scope
        assert_nil parser.call '7/32/2017-', scope
      end

      def test_modifier_with_date
        scope = stub(where: 'blerg')
        column = mock('column')
        column.expects(:eq).with(Date.new(2017, 7, 4))
        parser = DateParser.new column, modifier: 'mod'
        assert_nil parser.call '7/4/2017', scope
        refute_nil parser.call 'mod: 7/4/2017', scope
      end

      def test_modifier_with_closed_date_range
        scope = stub(where: 'blerg')
        column = mock('column')
        column.expects(:in).with(Date.new(2017, 7)..Date.new(2017, 7, 31))
        parser = DateParser.new column, modifier: 'mod'
        assert_nil parser.call '7/1/2017-7/31/2017', scope
        refute_nil parser.call 'mod: 7/1/2017-7/31/2017', scope
      end

      def test_modifier_with_open_date_range
        scope = stub(where: 'blerg')
        column = mock('column')
        column.expects(:gteq).with(Date.new(2017, 7, 31))
        parser = DateParser.new column, modifier: 'mod'
        assert_nil parser.call '7/31/2017-', scope
        refute_nil parser.call 'mod: 7/31/2017-', scope
      end

      def test_append_to_chain
        scope = mock('scope', where: 'blerg')
        scope.expects(:joins).with(:relation).returns(scope)
        column = stub('column', eq: nil)
        parser = DateParser.new column do |chain|
          chain.joins(:relation)
        end
        parser.call '10/3', scope
      end
    end
    # rubocop:enable Metrics/ClassLength
  end
end
