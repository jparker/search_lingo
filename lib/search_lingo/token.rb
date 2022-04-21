# frozen-string-literal: true

require 'delegate'
require 'search_lingo/constants'

module SearchLingo
  ##
  # Single token from a query string. A token consists of a term an an optional
  # modifier. The term may be a word or multiple words contained within double
  # quotes. The modifier is one or more alphanumeric characters. The modifier
  # and term and separated by a colon followed by zero or more whitespace
  # characters.
  #
  # The following are examples of tokens:
  #
  #   Token.new('foo')
  #   Token.new('"foo bar"')
  #   Token.new('foo: bar')
  #   Token.new('foo: "bar baz"')
  class Token < DelegateClass(String)
    ##
    # Returns the modifier portion of the token. Returns +nil+ if token does
    # not have a modifier.
    #
    #   Token.new('foo: bar').modifier # => "foo"
    #   Token.new('bar').modifier      # => nil
    def modifier
      self[SIMPLE_OR_COMPOUND_TOKEN_WITH_GROUPING, 1]
    end

    alias operator modifier

    ##
    # Returns the term portion of the token. If the term is wrapped in quotes,
    # they are removed.
    #
    #   Token.new('foo: bar').term  # => "bar"
    #   Token.new('bar').term       # => "bar"
    #   Token.new('"bar baz"').term # => "bar baz"
    #   Token.new('""').term        # => ""
    def term
      self[SIMPLE_OR_COMPOUND_TOKEN_WITH_GROUPING, 2].delete_prefix('"').delete_suffix('"')
    end

    ##
    # Returns +true+ if token has a modifier and +false+ otherwise.
    #
    #   Token.new('foo: bar').compound? # => true
    #   Token.new('bar').compound?      # => false
    def compound?
      !modifier.nil? && !modifier.empty?
    end

    def inspect # :nodoc:
      format '#<%<cls>s String(%<str>s) modifier=%<mod>s term=%<term>s>',
             cls: self.class,
             str: super,
             mod: modifier.inspect,
             term: term.inspect
    end
  end
end
