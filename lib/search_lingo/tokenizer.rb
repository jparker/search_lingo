require 'forwardable'
require 'strscan'
require 'search_lingo/constants'
require 'search_lingo/token'

module SearchLingo
  class Tokenizer
    include Enumerable
    extend Forwardable

    SIMPLE_TOKEN   = /#{TERM}/
    COMPOUND_TOKEN = /(?:#{OPERATOR}:[[:space:]]*)?#{TERM}/
    DELIMITER      = /[[:space:]]*/

    def initialize(query)
      @scanner = StringScanner.new query.strip
    end

    def each
      return to_enum(__callee__) unless block_given?

      until scanner.eos?
        yield self.next
      end
    end

    def next
      scanner.skip DELIMITER
      token = scanner.scan COMPOUND_TOKEN
      raise StopIteration unless token
      Token.new token
    end

    def_delegator :scanner, :reset

    def simplify
      scanner.unscan
      Token.new scanner.scan SIMPLE_TOKEN
    end

    private

    attr_reader :scanner
  end
end
