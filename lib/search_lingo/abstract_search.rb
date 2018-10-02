require 'search_lingo/tokenizer'

module SearchLingo
  class AbstractSearch
    attr_reader :query, :scope

    ##
    # Instantiates a new search object. +query+ is the string that is to be
    # parsed and compiled into an actual query. If +query+ is falsey, an empty
    # string will be used. +scope+ is the object to which the compiled query
    # should be sent, e.g., an +ActiveRecord+ model.
    def initialize(query, scope)
      @query = query || ''
      @scope = scope
    end

    ##
    # Returns an list of parsers that have been added to this class.
    def self.parsers
      @parsers ||= []
    end

    ##
    # Adds a new parser to the list of parsers used by this class.
    #
    # The parser may be given as an anonymous block or as any argument which
    # responds to +#call+. The parser will be send +#call+ with a single
    # argument which will be a token from the query string.
    #
    # If both a callable object and a block are given, or if neither a callable
    # object nor a block are given, an +ArgumentError+ will be raised.
    #
    #   class MyParser
    #     def call(token)
    #       # return something
    #     end
    #   end
    #
    #   class MySearch < SearchLingo::AbstractSearch
    #     parser MyParser.new
    #     parser do |token|
    #       # return something
    #     end
    #   end
    def self.parser(parser = nil, &block)
      unless block_given? ^ parser.respond_to?(:call)
        raise ArgumentError, 'parse must be called with callable OR block'
      end
      parsers << (parser || block)
    end

    ##
    # Delegates to SearchLingo::AbstractSearch.parsers.
    def parsers
      self.class.parsers
    end

    ##
    # Returns the results of executing the search.
    def results
      @results ||= load_results
    end

    ##
    # Load search results by composing query string tokens into a query chain.
    #
    # @query is borken down into tokens, and each token is passed through the
    # list of defined parsers. If a parser is successful, +:match+ is thrown,
    # processing moves on to the next token. If none of the parsers succeed and
    # the token is compound, the token is simplified and reprocessed as before.
    # If still no parser succeeds, fall back on +#default_parse+.
    def load_results
      tokenizer.reduce(scope) do |chain, token|
        catch(:match) do
          # 1. Try each parser with token until :match is thrown.
          parse token, chain

          # 2. If :match not thrown and token is compund, simplify and retry.
          if token.compound?
            token = tokenizer.simplify
            parse token, chain
          end

          # 3. If :match still not thrown, fall back on default parser.
          default_parse token, chain
        end
      end
    end

    ##
    # Returns a +SearchLingo::Tokenizer+ for @query.
    def tokenizer
      @tokenizer ||= Tokenizer.new query
    end

    ##
    # Passes +token+ to each parser in turn. If a parser succeeds, throws
    # +:match+ with the result.
    #
    # A parser succeeds if +call+ returns a truthy value. A successful parser
    # will typically send something to +chain+ and return the result. In this
    # way, the tokens of the search are reduced into a composed query.
    def parse(token, chain)
      parsers.each do |parser|
        result = parser.call token, chain
        throw :match, result if result
      end
      nil
    end

    ##
    # The default way to handle a token which could not be parsed by any of the
    # other parsers.
    #
    # This is a skeletal implementation that raises +NotImplementedError+.
    # Child classes should provide their own implementation. At a minimum, that
    # implementation should return +chain+. (Doing so would ignore +token+.)
    def default_parse(token, chain)
      raise NotImplementedError,
        "#default_parse must be implemented by #{self.class}"
    end
  end
end
