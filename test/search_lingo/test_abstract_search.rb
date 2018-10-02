require 'search_lingo/abstract_search'
require 'minitest_helper'

module SearchLingo
  class TestAbstractSearch < Minitest::Test # :nodoc:
    def test_query_reader
      search = AbstractSearch.new 'foo', nil
      assert_equal 'foo', search.query
    end

    def test_query_is_converted_to_empty_string_if_nil
      search = AbstractSearch.new nil, nil
      assert_equal '', search.query
    end

    def test_parsers_defaults_to_an_empty_array
      cls = Class.new AbstractSearch
      assert_empty cls.parsers
    end

    def test_define_parser_with_callable_object
      my_parser = ->(_token, _chain) { _chain }
      cls = Class.new(AbstractSearch) do
        parser my_parser
      end
      assert_equal 1, cls.parsers.size
    end

    def test_define_parser_with_block
      cls = Class.new(AbstractSearch) do
        parser { |_token, _chain| _chain }
      end
      assert_equal 1, cls.parsers.size
    end

    def test_define_parser_without_arguments
      err = assert_raises(ArgumentError) do
        Class.new(AbstractSearch) do
          parser
        end
      end
      assert_equal 'parse must be called with callable OR block', err.message
    end

    def test_define_parser_with_conflicting_arguments
      err = assert_raises(ArgumentError) do
        Class.new(AbstractSearch) do
          parser(->(_token, _chain) { }) { |_token, _chain| }
        end
      end
      assert_equal 'parse must be called with callable OR block', err.message
    end

    def test_descendents_of_abstract_class_keep_independent_lists_of_parsers
      cls1 = Class.new AbstractSearch
      cls2 = Class.new AbstractSearch
      refute_same cls1.parsers, cls2.parsers
    end

    def test_parse_iterates_over_each_parser_until_one_returns_truthy_value
      scope = mock('filter chain')
      scope.expects(:foo).with('foo').returns(scope)
      scope.expects(:bar).with('bar').returns(scope)
      cls = Class.new AbstractSearch do
        parser do |token, chain|
          chain.foo(token) if token == 'foo'
        end
        parser do |token, chain|
          chain.bar(token) if token == 'bar'
        end
      end
      cls.new('foo bar', scope).results
    end

    def test_parse_makes_second_pass_with_simplified_token
      scope = mock('filter chain')
      scope.expects(:foo).with('foo:').returns(scope)
      scope.expects(:bar).with('bar').returns(scope)
      cls = Class.new AbstractSearch do
        parser do |token, chain|
          chain.foo(token) if token == 'foo:'
        end
        parser do |token, chain|
          chain.bar(token) if token == 'bar'
        end
      end
      cls.new('foo: bar', scope).results
    end

    def test_parse_falls_back_on_default_parse
      scope = mock('filter chain')
      scope.expects(:default).with('foo').returns(scope)
      scope.expects(:default).with('bar').returns(scope)
      cls = Class.new AbstractSearch do
        parser { |_token, _chain| nil }

        def default_parse(token, chain)
          chain.default(token)
        end
      end
      cls.new('foo bar', scope).results
    end

    def test_parse_falls_back_on_default_parse_with_simplified_token
      scope = mock('filter chain')
      scope.expects(:foo).with('foo:').returns(scope)
      scope.expects(:default).with('bar').returns(scope)
      cls = Class.new AbstractSearch do
        parser do |token, chain|
          chain.foo(token) if token == 'foo:'
        end

        def default_parse(token, chain)
          chain.default(token)
        end
      end
      cls.new('foo: bar', scope).results
    end

    def test_default_parse_raises_NotImplementedError
      cls = Class.new AbstractSearch
      assert_raises(NotImplementedError) do
        cls.new(nil, nil).default_parse nil, nil
      end
    end
  end
end
