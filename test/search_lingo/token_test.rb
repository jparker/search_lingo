# frozen-string-literal: true

require 'search_lingo/token'
require 'minitest_helper'

module SearchLingo
  class TokenTest < Minitest::Test # :nodoc:
    def test_simple_token
      token = Token.new 'foo'
      assert_nil token.modifier
      assert_equal 'foo', token.term
    end

    def test_simple_quoted_token
      token = Token.new '"foo bar"'
      assert_nil token.modifier
      assert_equal 'foo bar', token.term
    end

    def test_empty_quoted_token
      token = Token.new '""'
      assert_nil token.modifier
      assert_empty token.term
    end

    def test_compound_token
      token = Token.new 'foo: bar'
      assert_equal 'foo', token.modifier
      assert_equal 'bar', token.term
    end

    def test_compound_token_with_quoted_term
      token = Token.new 'foo: "bar baz"'
      assert_equal 'foo', token.modifier
      assert_equal 'bar baz', token.term
    end

    def test_compound_token_with_empty_quoted_term
      token = Token.new 'foo: ""'
      assert_equal 'foo', token.modifier
      assert_empty token.term
    end

    def test_compound_token_with_no_space_after_modifier
      token = Token.new 'foo:bar'
      assert_equal 'foo', token.modifier
      assert_equal 'bar', token.term
    end

    def test_simple_token_that_looks_like_an_modifier
      token = Token.new 'foo:'
      assert_nil token.modifier
      assert_equal 'foo:', token.term
    end

    def test_compound_token_wrapped_in_quotes_is_actually_a_simple_token
      token = Token.new '"foo: bar"'
      assert_nil token.modifier
      assert_equal 'foo: bar', token.term
    end

    def test_match_is_delegated_to_original_string
      string = mock('string')
      string.expects(:match).with(/foo/)
      token = Token.new string
      token.match(/foo/)
    end

    def test_to_s_is_delegated_to_original_string
      string = stub(to_s: 'foo')
      token  = Token.new string
      assert_equal 'foo', token.to_s
    end
  end
end
