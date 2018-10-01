require 'search_lingo/tokenizer'

module SearchLingo
  class AbstractSearch
    attr_reader :query

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
    # Constructs and performs the query.
    def load_results
      conditions.inject(scope) do |query, condition|
        query.public_send(*condition)
      end
    end

    ##
    # Returns an +Array+ of compiled query parameters.
    #
    # @query is broken down into tokens, and each token is passed through the
    # list of defined parsers. If a parser is successful, +:match+ is thrown,
    # the compiled condition is saved, and processing moves on to the next
    # token.  If none of the parsers succeeds and the token is compound, that
    # is, it has both a modifier and a term, the token is simplified, and
    # reprocessed through the list of parsers. As during the first pass, if a
    # parser succeeds, +:match+ is thrown, the compiled condition for the now
    # simplified token is saved, and processing moves on to the next token (the
    # remains of the original compound token). If none of the parsers succeeds
    # during the second pass, the now simplified token is finally sent to
    # +#default_parse+, and whatever it returns will be saved as the compiled
    # condition.
    def conditions
      tokenizer.inject([]) do |conditions, token|
        conditions << catch(:match) do
          # 1. Try each parser with the token until :match is thrown.
          parse token

          # 2. If :match not thrown and token is compound, simplify and try again.
          if token.compound?
            token = tokenizer.simplify
            parse token
          end

          # 3. If :match still not thrown, fallback on default parser.
          default_parse token
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
    # +:match+ with the compiled result.
    #
    # A parser succeeds if +call+ returns a truthy value. The return value of a
    # successful parser will be splatted and sent to @scope using
    # +public_send+.
    def parse(token)
      parsers.each do |parser|
        result = parser.call token
        throw :match, result if result
      end
      nil
    end

    ##
    # Raises +NotImplementedError+. Classes which inherit from
    # SearchLingo::AbstractSearch must provide their own implementation, and it
    # should *always* succeed.
    def default_parse(token)
      raise NotImplementedError,
        "#default_parse must be implemented by #{self.class}"
    end

    ##
    # Returns @scope.
    #
    # You may override this method in your search class if you want to ensure
    # additional messages are sent to search scope before executing the query.
    # For example, if @scope is an +ActiveRecord+ model, you might want to join
    # additional tables.
    def scope
      @scope
    end
  end
end
