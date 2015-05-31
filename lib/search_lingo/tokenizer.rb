require 'forwardable'
require 'strscan'

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
            token.sub! /"([^"]*)"\Z/, '\1'
            yielder << token
          end
          scanner.skip DELIMITER
        end
      end
    end

    def_delegator :scanner, :reset
    def_delegators :enum, :each, :next

    def simplify
      scanner.unscan
      scanner.scan(SIMPLE).tap { scanner.skip DELIMITER }
    end

    private

    attr_reader :scanner
  end
end
