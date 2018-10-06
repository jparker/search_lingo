# frozen-string-literal: true

require 'search_lingo/tokenizer'
require 'minitest_helper'

module SearchLingo
  class TestTokenizer < Minitest::Test # :nodoc:
    def test_empty_query_string
      tokenizer = Tokenizer.new ''
      assert_empty tokenizer.to_a
    end

    def test_blank_query_string
      tokenizer = Tokenizer.new " \t\n"
      assert_empty tokenizer.to_a
    end

    def test_simple_tokens
      tokenizer = Tokenizer.new 'foo bar'
      assert_equal %w[foo bar], tokenizer.to_a
    end

    def test_quoted_tokens
      tokenizer = Tokenizer.new '"foo bar" "baz"'
      assert_equal ['"foo bar"', '"baz"'], tokenizer.to_a
    end

    def test_compound_tokens
      tokenizer = Tokenizer.new 'foo: bar baz: "froz quux"'
      assert_equal ['foo: bar', 'baz: "froz quux"'], tokenizer.to_a
    end

    def test_compound_tokens_without_space_after_modifier
      tokenizer = Tokenizer.new 'foo:bar baz:"froz quux"'
      assert_equal ['foo:bar', 'baz:"froz quux"'], tokenizer.to_a
    end

    def test_modifiers_are_limited_to_alphanumeric_characters
      tokenizer = Tokenizer.new 'foo: bar Foo: bar 42: forty-two bogus!: foo'
      assert_equal 'foo: bar', tokenizer.next
      assert_equal 'Foo: bar', tokenizer.next
      assert_equal '42: forty-two', tokenizer.next
      assert_equal 'bogus!:', tokenizer.next
      assert_equal 'foo', tokenizer.next

      # TODO: Should we let modifiers have dashes?
    end

    def test_lots_of_tokens
      tokenizer = Tokenizer.new 'foo bar: baz "froz quux"'
      assert_equal ['foo', 'bar: baz', '"froz quux"'], tokenizer.to_a
    end

    def test_tokenizer_does_not_choke_on_superfluous_spaces
      tokenizer = Tokenizer.new "  foo\t\tbar\r\n"
      assert_equal %w[foo bar], tokenizer.to_a
    end

    def test_reset
      tokenizer = Tokenizer.new 'foo'
      assert_equal 'foo', tokenizer.next
      assert_raises(StopIteration) { tokenizer.next }
      tokenizer.reset
      assert_equal 'foo', tokenizer.next
    end

    def test_simplify_a_compound_token
      tokenizer = Tokenizer.new('foo: bar')
      assert_equal 'foo: bar', tokenizer.next
      assert_equal 'foo:', tokenizer.simplify
    end

    def test_simplify_a_simple_token
      tokenizer = Tokenizer.new('foo')
      assert_equal 'foo', tokenizer.next
      assert_equal 'foo', tokenizer.simplify
    end

    def test_simplify_rewinds_the_scanner
      tokenizer = Tokenizer.new('foo: "bar baz"')
      assert_equal 'foo: "bar baz"', tokenizer.next
      assert_raises(StopIteration) { tokenizer.next }

      tokenizer.reset

      assert_equal 'foo: "bar baz"', tokenizer.next
      assert_equal 'foo:', tokenizer.simplify
      assert_equal '"bar baz"', tokenizer.next
    end
  end
end
