require 'forwardable'
require 'strscan'

module SearchLingo
  class Tokenizer
    include Enumerable
    extend Forwardable

    SIMPLE    = %r{ "[^"]*" | [[:graph:]]+ }x
    COMPOUND  = %r{ (?:[[:graph:]]+:[[:space:]]*)? #{SIMPLE} }x
    DELIMITER = %r{ [[:space:]]* }x

    def initialize(query)
      @scanner = StringScanner.new query.strip
    end

    def_delegator :scanner, :reset

    def each
      until scanner.eos?
        token = scanner.scan COMPOUND
        token.sub! /"([^"]*)"\Z/, '\1'
        yield token
        scanner.skip DELIMITER
      end
    end

    def next
      take(1).first
    end

    def simplify
      scanner.unscan
      scanner.scan(SIMPLE).tap do
        scanner.skip DELIMITER
      end
    end

    private

    attr_reader :scanner
  end
end
