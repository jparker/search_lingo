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

    def enum
      Enumerator.new do |yielder|
        until scanner.eos?
          token = scanner.scan COMPOUND
          if token
            yielder << Token.new(token)
          end
          scanner.skip DELIMITER
        end
      end
    end

    def_delegator :scanner, :reset
    def_delegators :enum, :each, :next

    def simplify
      scanner.unscan
      Token.new(scanner.scan(SIMPLE)).tap do
        scanner.skip DELIMITER
      end
    end

    private

    attr_reader :scanner
  end
end
