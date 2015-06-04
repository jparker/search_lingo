# SearchLingo

SearchLingo is a framework for defining simple, user-friendly query languages
and translating them into their underlying queries.

It was originally designed after I found myself implementing the same basic
query parsing over and over again across different projects. I wanted a way to
simplify the process without having to worry about application-specific aspects
of searching.

The way the searches themselves are performed lies outside the scope of this
project. Although originally designed to work with basic searching with
ActiveRecord models, it should be usable with other data stores provided they
let you chain queries together onto a single object.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'search_lingo'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install search_lingo

## Usage

Create a class which inherits from SearchLingo::AbstractSearch. Provide an
implementation of <code>#default_parse</code> in that class. Register parsers
for specific types of search tokens using the <code>parser</code> class method.

Instantiate your search class by passing in the query string and the scope on
which to perform the search. Use the <code>#results</code> method to compile
the search and return the results.

Take a look at the examples/ directory for more concrete examples.

## How It Works

A search is instantiated with a query string and a search scope (commonly an
ActiveRecord model). The search breaks the query string down into a series of
tokens, and each token is processed by a declared series of parsers. If a
parser succeeds, the process immediately terminates and advances to the next
token. If none of the declared parsers succeeds, and the token is compound --
that is, the token is composed of an operator and a term (e.g., "foo: bar"),
the token is simplified and then processed by the declared parsers again. If
the second pass also fails, then the (now simplified) token falls through to
the <code>#default_parse</code> method defined by the search class. (It is
important that this method be implemented in such a way that it always
succeeds.)

## Search Classes

Search classes should inherit from SearchLingo::AbstractSearch and they should
override the <code>#default_parse</code> instance method. It is important that
this method be defined in such a way that it always succeeds, as the results
will be sent to the query object via <code>#public_send</code>. In addtion, the
class method <code>parser</code> can be used to declare additional parsers that
should be used by the search class. (See the section "Parsing" for more
information on what makes a suitable parser.)

## Parsers

Any object that can respond to the <code>#call</code> method can be used as a
parser. If the parser succeeds, it should return an Array of arguments that can
be sent to the query object using <code>#public_send</code>, e.g.,
<code>[:where, { id: 42 }]</code>. If the parser fails, it should return a
falsey value (typically nil).

For very simple parsers which need not be reusable, you can pass the
parsing logic to the <code>parser</code> method as a block:

    class MySearch < SearchLingo::AbstractSearch
      parser do |token|
        token.match /\Aid:[[:space:]]*([[:digit:]]+)\Z/ do |m|
          [:where, { id: m[1] }]
        end
      end
    end

Parsers can also be implemented as lambdas:

    module Parsers
      ID_PARSER = lambda do |token|
        token.match h/\Aid:[[:space:]]*([[:digit:]]+)\Z/ do |m|
          [:where, { id: m[1] }]
        end
      end
    end

    class MySearch < SearchLingo::AbstractSearch
      parser Parsers::ID_PARSER
    end

    class MyOtherSearch < SearchLingo::AbstractSearch
      parser Parsers::ID_PARSER
    end

Finally, for the most complicated cases, you could implement parsers as
classes:

    module Parsers
      class IdParser
        def initialize(table, operator = nil)
          @table = table
          @prefix = /#{operator}:\s*/ if operator
        end

        def call(token)
          token.match /\A#{@prefix}([[:digit:]]+)\Z do |m|
            [:where, { @table => { id: m[1] } }]
          end
        end
      end
    end

    class EventSearch < SearchLingo::AbstractSearch
      parser Parsers::IdParser.new :events                 # => match "42"
      parser Parsers::IdParser.new :categories, 'category' # => match "category: 42"
    end

    class CategorySearch < SearchLingo::AbstractSearch
      parser Parsers::IdParser.new :categories
    end

## Tokenization

Queries are comprised of one or more tokens separated by spaces. A simple token
is a term which can be a single word (or date, number, etc.) or multiple terms
within a pair of double quotes. A compound token is a simple token preceded by
an operator followed by zero or more spaces.

    QUERY          := TOKEN*
    TOKEN          := COMPOUND_TOKEN | TERM
    COMPOUND_TOKEN := OPERATOR TERM
    OPERATOR       := [[:graph:]]+:
    TERM           := "[^"]*" | [[:graph:]]+

Terms can be things like:

* foo
* "foo bar"
* 6/14/15
* 1000.00

Operators can be things like:

* foo:
* bar_baz:

(If you want to perform a query with a term that could potentially be parsed as
an operator, you would place the term in quotes, i.e., "foo:".)

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run
`bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To
release a new version, update the version number in `version.rb`, and then run
`bundle exec rake release` to create a git tag for the version, push git
commits and tags, and push the `.gem` file to
[rubygems.org](https://rubygems.org).

## Contributing

1. Fork it ( https://github.com/jparker/search_lingo/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
