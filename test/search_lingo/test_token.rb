require 'search_lingo/token'
require 'minitest_helper'

module SearchLingo
  class TestToken < Minitest::Test
    def test_simple_token
      token = Token.new 'foo'
      assert_nil token.operator
      assert_equal 'foo', token.term
    end

    def test_simple_token_in_quotes
      token = Token.new '"foo bar"'
      assert_nil token.operator
      assert_equal 'foo bar', token.term
    end

    def test_compound_token
      token = Token.new 'foo: bar'
      assert_equal 'foo', token.operator
      assert_equal 'bar', token.term
    end

    def test_compound_token_with_term_in_quotes
      token = Token.new 'foo: "bar baz"'
      assert_equal 'foo', token.operator
      assert_equal 'bar baz', token.term
    end

    def test_compound_token_with_no_space_after_operator
      token = Token.new 'foo:bar'
      assert_equal 'foo', token.operator
      assert_equal 'bar', token.term
    end

    def test_simple_token_that_looks_like_an_operator
      token = Token.new 'foo:'
      assert_nil token.operator
      assert_equal 'foo:', token.term
    end

    def test_match_is_delegated_to_original_string
      string = Minitest::Mock.new
      token  = Token.new string
      string.expect :match, nil, [/foo/]

      token.match /foo/

      string.verify
    end

    def test_to_s_is_delegated_to_original_string
      string = Minitest::Mock.new
      token  = Token.new string
      string.expect :to_s, 'foo'

      token.to_s

      string.verify
    end
  end
end
