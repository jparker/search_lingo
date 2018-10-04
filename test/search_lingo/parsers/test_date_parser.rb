require 'search_lingo/parsers/date_parser'
require 'minitest_helper'

module SearchLingo::Parsers
  class TestDateParser < Minitest::Test # :nodoc:
    def test_MMDDYYYY
      column = mock('column')
      column.expects(:eq).with(Date.new(2017, 7, 4))
      parser = DateParser.new column
      parser.call '7/4/2017', mock(where: nil)
    end

    def test_MMDDYY
      column = mock('column')
      column.expects(:eq).with(Date.new(2017, 7, 4))
      parser = DateParser.new column
      parser.call '7/4/17', mock(where: nil)
    end

    def test_MMDD
      column = mock('column')
      column.expects(:eq).with(Date.new(1776, 7, 4))
      Date.stub :today, Date.new(1776, 12, 25) do
        parser = DateParser.new column
        parser.call '7/4', mock(where: nil)
      end
    end

    def test_MMDDYYYY_MMDDYYYY
      column = mock('column')
      column.expects(:in).with(Date.new(2017)..Date.new(2017, 6, 30))
      parser = DateParser.new column
      parser.call '1/1/2017-6/30/2017', mock(where: nil)
    end

    def test_MMDDYY_MMDDYY
      column = mock('column')
      column.expects(:in).with(Date.new(2017)..Date.new(2017, 6, 30))
      parser = DateParser.new column
      parser.call '1/1/17-6/30/17', mock(where: nil)
    end

    def test_MMDD_MMDD
      column = mock('column')
      column.expects(:in).with(Date.new(1776, 7)..Date.new(1776, 7, 31))
      Date.stub :today, Date.new(1776, 7, 4) do
        parser = DateParser.new column
        parser.call '7/1-7/31', mock(where: nil)
      end
    end

    def test_MMDDYY_MMDD
      column = mock('column')
      column.expects(:in).with(Date.new(2017, 7)..Date.new(2017, 7, 31))
      Date.stub :today, Date.new(1776, 7, 4) do
        parser = DateParser.new column
        parser.call '7/1/17-7/31', mock(where: nil)
      end
    end

    def test_MMDD_MMDDYY
      column = mock('column')
      column.expects(:in).with(Date.new(1776, 7)..Date.new(2017, 7, 31))
      Date.stub :today, Date.new(1776, 7, 4) do
        parser = DateParser.new column
        parser.call '7/1-7/31/17', mock(where: nil)
      end
    end

    def test_less_than_MMDDYYYY
      column = mock('column')
      column.expects(:lteq).with(Date.new(2017, 7, 1))
      parser = DateParser.new column
      parser.call '-7/1/2017', mock(where: nil)
    end

    def test_less_than_MMDDYY
      column = mock('column')
      column.expects(:lteq).with(Date.new(2017, 7, 1))
      parser = DateParser.new column
      parser.call '-7/1/17', mock(where: nil)
    end

    def test_less_than_MMDD
      column = mock('column')
      column.expects(:lteq).with(Date.new(1776, 7, 1))
      Date.stub :today, Date.new(1776, 7, 4) do
        parser = DateParser.new column
        parser.call '-7/1', mock(where: nil)
      end
    end

    def test_greater_than_MMDDYYYY
      column = mock('column')
      column.expects(:gteq).with(Date.new(2017, 7, 1))
      parser = DateParser.new column
      parser.call '7/1/2017-', mock(where: nil)
    end

    def test_greater_than_MMDDYY
      column = mock('column')
      column.expects(:gteq).with(Date.new(2017, 7, 1))
      parser = DateParser.new column
      parser.call '7/1/17-', mock(where: nil)
    end

    def test_greater_than_MMDD
      column = mock('column')
      column.expects(:gteq).with(Date.new(1776, 7, 1))
      Date.stub :today, Date.new(1776, 7, 4) do
        parser = DateParser.new column
        parser.call '7/1-', mock(where: nil)
      end
    end

    def test_invalid_date
      chain = stub(where: 'blerg')
      column = mock('column')
      column.expects(:eq).with(Date.new(2016, 2, 29))
      parser = DateParser.new column
      refute_nil parser.call '2/29/2016', chain
      assert_nil parser.call '2/29/2017', chain
      assert_nil parser.call 'bogus', chain
    end

    def test_invalid_date_range
      chain = stub(where: 'blerg')
      column = stub('column')
      parser = DateParser.new column
      assert_nil parser.call '7/1/2017-7/32/2017', chain
      assert_nil parser.call '-7/32/2017', chain
      assert_nil parser.call '7/32/2017-', chain
    end

    def test_modifier
      chain = stub(where: 'blerg')
      column = mock('column')
      column.expects(:eq).with(Date.new(2017, 7, 4))
      column.expects(:in).with(Date.new(2017, 7)..Date.new(2017, 7, 31))
      column.expects(:gteq).with(Date.new(2017, 7, 31))
      parser = DateParser.new column, modifier: 'mod'

      assert_nil parser.call '7/4/2017', chain
      assert_nil parser.call '7/1/2017-7/31/2017', chain
      assert_nil parser.call '7/31/2017-', chain

      refute_nil parser.call 'mod: 7/4/2017', chain
      refute_nil parser.call 'mod: 7/1/2017-7/31/2017', chain
      refute_nil parser.call 'mod: 7/31/2017-', chain
    end

    def test_append_to_chain
      chain  = mock('scope', where: 'blerg')
      chain.expects(:joins).with(:relation).returns(chain)
      column = stub('column', eq: nil)
      parser = DateParser.new column do |chain|
        chain.joins(:relation)
      end
      parser.call '10/3', chain
    end
  end
end
