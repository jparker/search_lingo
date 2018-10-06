# frozen-string-literal: true

require 'search_lingo/parsers/mdy'
require 'minitest_helper'

module SearchLingo
  module Parsers
    class MDYTest < Minitest::Test # :nodoc:
      def test_parse_mmddyyyy
        assert_equal Date.new(2015, 6, 1), MDY.parse('6/1/2015')
        assert_equal Date.new(2016, 2, 29), MDY.parse('2/29/2016')
        assert_equal Date.new(0, 12, 25), MDY.parse('12/25/0000')
      end

      def test_parse_mmddyy
        assert_equal Date.new(2015, 6, 1), MDY.parse('6/1/15')
        assert_equal Date.new(1989, 6, 1), MDY.parse('6/1/89')
        assert_equal Date.new(2009, 12, 31), MDY.parse('12/31/09')
      end

      def test_parse_mmdd_relative_to_implicit_reference_date
        Date.stub :today, Date.new(2001, 10, 2) do
          assert_equal Date.new(2001, 1, 1), MDY.parse('1/1')
          assert_equal Date.new(2000, 10, 3), MDY.parse('10/3')
          assert_nil MDY.parse('2/29')
        end
      end

      def test_parse_mmdd_relative_to_explicit_reference_date
        ref = Date.new 2016, 10, 2
        Date.stub :today, Date.new(2001, 12, 31) do
          assert_equal Date.new(2016, 1, 1),
                       MDY.parse('1/1', relative_to: ref)
          assert_equal Date.new(2015, 10, 3),
                       MDY.parse('10/3', relative_to: ref)
          assert_equal Date.new(2016, 2, 29),
                       MDY.parse('2/29', relative_to: ref)
        end
      end

      def test_parse_with_invalid_mdy_format
        assert_nil MDY.parse '2/29/2017'
        assert_nil MDY.parse '25/12/2015'
        assert_nil MDY.parse '1/32/2015'
      end

      def test_parse_with_invalid_md_format
        assert_nil MDY.parse '31/1'
        assert_nil MDY.parse '2/29', relative_to: Date.new(1999)
      end
    end
  end
end
