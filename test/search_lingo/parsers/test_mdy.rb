require 'search_lingo/parsers/mdy'
require 'minitest_helper'

module SearchLingo::Parsers
  class TestMDY < Minitest::Test # :nodoc:
    def test_parse_MMDDYYYY
      assert_equal Date.new(2015, 6, 1), MDY.parse('6/1/2015')
    end

    def test_parse_MMDDYY
      assert_equal Date.new(2015, 6, 1), MDY.parse('6/1/15')
      assert_equal Date.new(1989, 6, 1), MDY.parse('6/1/89')
    end

    def test_parse_MMDD_relative_to_implicit_reference_date
      Date.stub :today, Date.new(2000, 7, 1) do
        assert_equal Date.new(2000, 6, 1), MDY.parse('6/1')
        assert_equal Date.new(2000, 7, 1), MDY.parse('7/1')
        # evaluated date always falls on or before reference date
        assert_equal Date.new(1999, 8, 1), MDY.parse('8/1')
      end
    end

    def test_parse_MMDD_relative_to_explicit_reference_date
      date = Date.new 2010, 7, 1
      Date.stub :today, Date.new(2000, 7, 1) do
        assert_equal Date.new(2010, 6, 1), MDY.parse('6/1', relative_to: date)
        assert_equal Date.new(2010, 7, 1), MDY.parse('7/1', relative_to: date)
        # evaluated date always falls on or before reference date
        assert_equal Date.new(2009, 8, 1), MDY.parse('8/1', relative_to: date)
      end
    end

    def test_parse_with_invalid_MDY_format
      assert_nil MDY.parse '25/12/2015'
      assert_nil MDY.parse '1/32/2015'
    end
  end
end
