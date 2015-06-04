# SearchLingo

SearchLingo is a framework for defining simple, user-friendly query languages
and translating them into their underlying queries.

Although designed originally to be used with simple searches using ActiveRecord
models, there is no dependency on ActiveRecord or Rails. The search classes you
define will provide the query object (commonly an ActiveRecord model or an
ActiveRecord::Relation), and the parsers you define will describe what messages
to send to the query object (typically things like <code>where</code> or a
named scope) to perform the search.

In theory, you should be able to write parsers to translate into queries for
non-ActiveRecord data stores.

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

## Search Classes

Search classes should inherit from SearchLingo::AbstractSearch and they should
override the <code>#default_parse</code> instance method. In addtion, the class
method <code>parser</code> can be used to declare additional parsers that
should be used by the search class. (See the section "Parsing" for more
information on what makes a suitable parser.)

## Parsers

Any object that can respond to the <code>#call</code> method can be used as a
parser. For very simple parsers which need not be reusable, you can pass the
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

TODO: Explain the tokenization process in greater detail.

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
