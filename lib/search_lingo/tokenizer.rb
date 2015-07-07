require 'forwardable'
require 'strscan'
require 'search_lingo/constants'
require 'search_lingo/token'

module SearchLingo
  class Tokenizer
    include Enumerable
    extend Forwardable

    ##
    # Pattern for matching a simple token (a term without a modifier).
    SIMPLE_TOKEN   = /#{TERM}/

    ##
    # Pattern for matching a compound token (a term with an optional modifier).
    COMPOUND_TOKEN = /(?:#{MODIFIER}:[[:space:]]*)?#{TERM}/

    ##
    # Pattern for matching the delimiter between tokens.
    DELIMITER      = /[[:space:]]*/

    def initialize(query) # :nodoc:
      @scanner = StringScanner.new query.strip
    end

    ##
    # Iterates over the query string. If called with a block, it yields each
    # token. If called without a block, it returns an +Enumerator+.
    def each
      return to_enum(__callee__) unless block_given?

      until scanner.eos?
        yield self.next
      end
    end

    ##
    # Returns a Token for the next token in the query string. When the end of
    # the query string is reached raises +StopIteration+.
    def next
      scanner.skip DELIMITER
      token = scanner.scan COMPOUND_TOKEN
      raise StopIteration unless token
      Token.new token
    end

    def_delegator :scanner, :reset

    ##
    # Rewinds the query string from the last returned token and returns a
    # Token for the next simple token.
    def simplify
      scanner.unscan
      Token.new scanner.scan SIMPLE_TOKEN
    end

    private

    attr_reader :scanner
  end
end
