require 'search_lingo/parsers/date_parser'
require 'minitest_helper'
require 'fake_arel_attribute'

module SearchLingo::Parsers
  class TestDateParser < Minitest::Test # :nodoc:
    def setup
      @column = FakeArelAttribute.new
    end

    def test_MMDDYYYY
      parser = DateParser.new @column
      expected = [:where, @column.eq(Date.new(2017, 7, 4))]
      assert_equal expected, parser.call('7/4/2017')
    end

    def test_MMDDYY
      parser = DateParser.new @column
      expected = [:where, @column.eq(Date.new(2017, 7, 4))]
      assert_equal expected, parser.call('7/4/17')
    end

    def test_MMDD
      Date.stub :today, Date.new(1776, 12, 25) do
        parser = DateParser.new @column
        expected = [:where, @column.eq(Date.new(1776, 7, 4))]
        assert_equal expected, parser.call('7/4')
      end
    end

    def test_MMDDYYYY_MMDDYYYY
      parser = DateParser.new @column
      expected = [:where, @column.in(Date.new(2017)..Date.new(2017, 6, 30))]
      assert_equal expected, parser.call('1/1/2017-6/30/2017')
    end

    def test_MMDDYY_MMDDYY
      parser = DateParser.new @column
      expected = [:where, @column.in(Date.new(2017)..Date.new(2017, 6, 30))]
      assert_equal expected, parser.call('1/1/17-6/30/17')
    end

    def test_MMDD_MMDD
      Date.stub :today, Date.new(1776, 7, 4) do
        parser = DateParser.new @column
        expected = [:where, @column.in(Date.new(1776, 7)..Date.new(1776, 7, 31))]
        assert_equal expected, parser.call('7/1-7/31')
      end
    end

    def test_MMDDYY_MMDD
      Date.stub :today, Date.new(1776, 7, 4) do
        parser = DateParser.new @column
        expected = [:where, @column.in(Date.new(2017, 7)..Date.new(2017, 7, 31))]
        assert_equal expected, parser.call('7/1/17-7/31')
      end
    end

    def test_MMDD_MMDDYY
      Date.stub :today, Date.new(1776, 7, 4) do
        parser = DateParser.new @column
        expected = [:where, @column.in(Date.new(1776, 7)..Date.new(2017, 7, 31))]
        assert_equal expected, parser.call('7/1-7/31/17')
      end
    end

    def test_less_than_MMDDYYYY
      parser = DateParser.new @column
      expected = [:where, @column.lteq(Date.new(2017, 7, 1))]
      assert_equal expected, parser.call('-7/1/2017')
    end

    def test_less_than_MMDDYY
      parser = DateParser.new @column
      expected = [:where, @column.lteq(Date.new(2017, 7, 1))]
      assert_equal expected, parser.call('-7/1/17')
    end

    def test_less_than_MMDD
      Date.stub :today, Date.new(1776, 7, 4) do
        parser = DateParser.new @column
        expected = [:where, @column.lteq(Date.new(1776, 7, 1))]
        assert_equal expected, parser.call('-7/1')
      end
    end

    def test_greater_than_MMDDYYYY
      parser = DateParser.new @column
      expected = [:where, @column.gteq(Date.new(2017, 7, 1))]
      assert_equal expected, parser.call('7/1/2017-')
    end

    def test_greater_than_MMDDYY
      parser = DateParser.new @column
      expected = [:where, @column.gteq(Date.new(2017, 7, 1))]
      assert_equal expected, parser.call('7/1/17-')
    end

    def test_greater_than_MMDD
      Date.stub :today, Date.new(1776, 7, 4) do
        parser = DateParser.new @column
        expected = [:where, @column.gteq(Date.new(1776, 7, 1))]
        assert_equal expected, parser.call('7/1-')
      end
    end

    def test_modifier
      parser = DateParser.new @column, modifier: 'mod'

      assert_nil parser.call '7/4/2017'
      refute_nil parser.call 'mod: 7/4/2017'

      assert_nil parser.call '7/1/2017-7/31/2017'
      refute_nil parser.call 'mod: 7/1/2017-7/31/2017'

      assert_nil parser.call '7/31/2017-'
      refute_nil parser.call 'mod: 7/31/2017-'
    end

    def test_invalid_date
      parser = DateParser.new @column
      refute_nil parser.call '2/29/2016'
      assert_nil parser.call '2/29/2017'
      assert_nil parser.call 'bogus'
    end

    def test_invalid_date_range
      parser = DateParser.new @column
      assert_nil parser.call '7/1/2017-7/32/2017'
      assert_nil parser.call '-7/32/2017'
      assert_nil parser.call '7/32/2017-'
    end
  end
end
