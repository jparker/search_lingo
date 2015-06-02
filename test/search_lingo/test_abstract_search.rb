require 'search_lingo/abstract_search'
require 'minitest_helper'

module SearchLingo
  class TestAbstractSearch < Minitest::Test
    def test_query_reader
      search = AbstractSearch.new 'foo', :scope
      assert_equal 'foo', search.query
    end

    def test_query_is_converted_to_empty_string_if_nil
      search = AbstractSearch.new nil, :scope
      assert_equal '', search.query
    end

    def test_scope_reader
      search = AbstractSearch.new '', :scope
      assert_equal :scope, search.scope
    end

    def test_parsers_returns_an_empty_array
      cls = Class.new AbstractSearch
      assert_empty cls.parsers
    end

    def test_parser_with_an_object
      parser = ->{}
      cls = Class.new AbstractSearch
      cls.parser parser
      assert_equal [parser], cls.parsers
    end

    def test_parser_with_a_block
      cls = Class.new AbstractSearch
      cls.parser { }
      refute_nil cls.parsers.first
    end

    def test_parser_with_no_arguments
      cls = Class.new AbstractSearch
      error = assert_raises(ArgumentError) { cls.parser }
      assert_equal '.parse must be called with callable or block', error.message
    end

    def test_descendents_of_abstract_class_have_distinct_parsers
      cls1 = Class.new AbstractSearch
      cls1.parser { }
      cls2 = Class.new AbstractSearch
      cls2.parser { }
      refute_equal cls1.parsers, cls2.parsers
    end

    def test_parse_calls_each_parser_with_token
      parser1 = Minitest::Mock.new
      parser1.expect :call, nil, ['foo']
      parser2 = Minitest::Mock.new
      parser2.expect :call, nil, ['foo']

      cls = Class.new AbstractSearch
      cls.parser parser1
      cls.parser parser2

      cls.new('', :scope).parse('foo')

      parser1.verify
      parser2.verify
    end

    def test_parse_throws_match_if_parser_returns_truthy_value
      cls = Class.new AbstractSearch
      cls.parser { [:foo] }
      cls.parser { flunk 'should not have been called' }
      search = cls.new '', :scope
      assert_throws(:match) { search.parse 'foo' }
    end

    def test_default_parse_raises_error
      cls = Class.new AbstractSearch
      search = cls.new '', :scope
      assert_raises(NotImplementedError) { search.default_parse 'foo' }
    end

    def test_conditions_when_token_falls_through_to_default_parser
      cls = Class.new AbstractSearch do
        def default_parse(token)
          [:foo, token.term]
        end
      end
      search = cls.new('foo', :scope)

      assert_equal [[:foo, 'foo']], cls.new('foo', :scope).conditions
    end

    def test_conditions_with_multiple_parsers
      cls = Class.new AbstractSearch
      cls.parser { |token| token.match(/\A(foo)\Z/) { |m| [:foo, m[1]] } }
      cls.parser { |token| token.match(/\A(bar)\Z/) { |m| [:bar, m[1]] } }
      search = cls.new('foo bar', :scope)

      assert_equal [[:foo, 'foo'], [:bar, 'bar']], search.conditions
    end

    def test_conditions_when_compound_token_is_matched
      cls = Class.new AbstractSearch do
        def default_parse(token)
          raise '#default_parse should not have been reached'
        end
      end
      cls.parser { |token| token.match(/\Afoo:\s*(.*)\Z/) { |m| [:foo, m[1]] } }

      assert_equal [[:foo, 'bar']], cls.new('foo: bar', :scope).conditions
    end

    def test_conditions_when_compound_token_is_simplified
      cls = Class.new AbstractSearch do
        def default_parse(token)
          [:where, token.term]
        end
      end
      search = cls.new('foo: bar', :scope)

      assert_equal [[:where, 'foo:'], [:where, 'bar']], search.conditions
    end

    def test_results_sends_conditions_to_scope
      cls = Class.new AbstractSearch
      cls.parser { |token| [:where, token.term] }

      scope = Minitest::Mock.new
      scope.expect(:where, scope, ['foo'])
      scope.expect(:where, scope, ['bar'])

      cls.new('foo bar', scope).results

      scope.verify
    end
  end
end
