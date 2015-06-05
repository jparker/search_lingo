require 'forwardable'
require 'strscan'
require 'search_lingo/token'

module SearchLingo
  class Tokenizer
    include Enumerable
    extend Forwardable

    SIMPLE    = %r{"[^"]*"|[[:graph:]]+}
    COMPOUND  = %r{(?:[[:graph:]]+:[[:space:]]*)?#{SIMPLE}}
    DELIMITER = %r{[[:space:]]*}

    def initialize(query)
      @scanner = StringScanner.new query.strip
    end

    def each
      until scanner.eos?
        yield self.next
      end
    end

    def next
      scanner.skip DELIMITER
      token = scanner.scan(COMPOUND) or raise StopIteration
      Token.new token
    end

    def_delegator :scanner, :reset

    def simplify
      scanner.unscan
      Token.new scanner.scan SIMPLE
    end

    private

    attr_reader :scanner
  end
end
