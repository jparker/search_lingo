require 'delegate'
require 'search_lingo/constants'

module SearchLingo
  class Token < DelegateClass(String)
    ##
    # Pattern for decomposing a token into a modifier and a term.
    STRUCTURE = /\A(?:(#{MODIFIER}):[[:space:]]*)?"?(.+?)"?\z/

    ##
    # Returns the modifier portion of the token. Returns +nil+ if token does
    # not have a modifier.
    #
    #   Token.new('foo: bar').modifier # => 'foo'
    #   Token.new('bar').modifier      # => nil
    def modifier
      self[STRUCTURE, 1]
    end

    alias_method :operator, :modifier

    ##
    # Returns the term portion of the token. If the term is wrapped in quotes,
    # they are removed.
    #
    #   Token.new('foo: bar').term  # => 'bar'
    #   Token.new('bar').term       # => 'bar'
    #   Token.new('"bar baz"').term # => 'bar baz'
    def term
      self[STRUCTURE, 2]
    end

    ##
    # Returns +true+ if token has a modifier and +false+ otherwise.
    #
    #   Token.new('foo: bar').compound? # => true
    #   Token.new('bar').compound?      # => false
    def compound?
      !!modifier
    end

    def inspect # :nodoc:
      '#<%s String(%s) modifier=%s term=%s>' %
        [self.class, super, modifier.inspect, term.inspect]
    end
  end
end
