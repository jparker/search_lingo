# frozen-string-literal: true

require 'search_lingo/tokenizer'

module SearchLingo
  ##
  # AbstractSearch is an abstract implementation from which search classes
  # should inherit.
  #
  # Search classes are instantiated with a query string and a default scope on
  # which to perform the search.
  #
  # Child classes must implement the #default_parse instance method, and they
  # may optionally register one or more parsers.
  #
  #   class MySearch < SearchLingo::AbstractSearch
  #     def default_parse(token, chain)
  #       chain.where attribute: token.term
  #     end
  #   end
  #
  #   class MyOtherSearch < SearchLingo::AbstractSearch
  #     parser SearchLingo::Parsers::DateParser.new Job.arel_table[:date]
  #
  #     parser do |token, chain|
  #       token.match(/\Aid: [[:space:]]* (?<id>[[:digit:]]+)\z/x) do |m|
  #         chain.where id: m[:id]
  #       end
  #     end
  #
  #     def default_parse(token, chain)
  #       chain.where Job.arel_table[:name].matches "%#{token.term}%"
  #     end
  #   end
  class AbstractSearch
    attr_reader :query, :scope, :logger

    ##
    # Instantiates a new search object. +query+ is the string that is to be
    # parsed and compiled into an actual query. If +query+ is falsey, an empty
    # string will be used. +scope+ is the object to which the compiled query
    # should be sent, e.g., an +ActiveRecord::Relation+.
    #
    #   MySearchClass.new 'foo bar: baz "froz quux"', Task.all
    def initialize(query, scope, logger: nil)
      @query  = query || ''
      @scope  = scope
      @logger = logger
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
    # Raises +ArgumentError+ if +parser+ does not respond to +#call+ and no
    # block is given.
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
      if parser.respond_to? :call
        parsers << parser
      elsif block_given?
        parsers << block
      else
        raise ArgumentError, 'parse must be called with block or callable object'
      end
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
    # @query is broken down into tokens and parses each one in turn. The
    # results of parsing each token are chained onto the end of +scope+ to
    # compose the query.
    def load_results
      tokenizer.reduce(scope) do |chain, token|
        parse token, chain
      end
    end

    ##
    # Returns a +SearchLingo::Tokenizer+ for @query.
    def tokenizer
      @tokenizer ||= Tokenizer.new query
    end

    ##
    # Passes +token+ and +chain+ through the array of parsers until +:match+ is
    # thrown. If none of the parsers match and the token is compound,
    # simplifies the token and reruns the parsers. If no parsers match after
    # the second pass or if the token was not compound, falls back on
    # `#default_parse`.
    def parse(token, chain)
      catch(:match) do
        run_parsers token, chain

        if token.compound?
          token = tokenizer.simplify
          run_parsers token, chain
        end

        logger&.debug "default_parse token=#{token.inspect}"
        default_parse token, chain
      end
    end

    ##
    # Passes +token+ to each parser in turn. If a parser succeeds, throws
    # +:match+ with the result.
    #
    # A parser succeeds if +call+ returns a truthy value. A successful parser
    # will typically send something to +chain+ and return the result. In this
    # way, the tokens of the search are reduced into a composed query.
    def run_parsers(token, chain)
      parsers.each do |parser|
        result = parser.call token, chain
        if result
          logger&.debug "parser:#{parser.inspect} token=#{token.inspect}"
          throw :match, result
        end
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
    def default_parse(_token, _chain)
      raise NotImplementedError,
            "#default_parse must be implemented by #{self.class}"
    end
  end
end
