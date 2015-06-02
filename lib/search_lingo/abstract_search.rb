require 'search_lingo/tokenizer'

module SearchLingo
  class AbstractSearch
    def initialize(query, scope, tokenizer: Tokenizer)
      @query = query || ''
      @scope = scope
      @tokenizer = tokenizer.new @query
    end

    attr_reader :query, :scope, :tokenizer

    def self.parsers
      @parsers ||= []
    end

    def self.parser(callable = nil, &block)
      unless callable || block_given?
        raise ArgumentError, '.parse must be called with callable or block'
      end
      if callable && block_given?
        warn "WARNING: parse called with callable and block (#{caller.first}"
      end

      parsers << (callable || block)
    end

    def parsers
      self.class.parsers
    end

    def results
      @results ||= conditions.inject(scope) do |query, condition|
        query.public_send(*condition)
      end
    end

    def conditions
      tokenizer.inject([]) do |conditions, token|
        conditions << catch(:match) do
          parse token
          if token.compound?
            token = tokenizer.simplify
            parse token
          end
          default_parse token
        end
      end
    end

    def parse(token)
      parsers.each do |parser|
        result = parser.call token
        throw :match, result if result
      end
    end

    def default_parse(token)
      raise NotImplementedError,
        "#default_parse must be implemented by #{self.class}"
    end
  end
end
