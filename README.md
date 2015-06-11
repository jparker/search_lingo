# [![Gem Version](https://badge.fury.io/rb/search_lingo.svg)](http://badge.fury.io/rb/search_lingo) [![Build Status](https://travis-ci.org/jparker/search_lingo.svg?branch=master)](https://travis-ci.org/jparker/search_lingo)

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
let you build complex queries by chaining together simpler queries.

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

Here is a simple example.

```ruby
class Task < ActiveRecord::Base
end

class TaskSearch < SearchLingo::AbstractSearch
  def default_parse(token)
    [:where, 'tasks.name LIKE ?', "%#{token}%"]
  end
end

TaskSearch.new('foo bar', Task).results
# => Task.where('tasks.name LIKE ?', '%foo%')
# ->   .where('tasks.name LIKE ?', '%bar%')

TaskSearch.new('"foo bar"', Task).results
# => Task.where('tasks.name LIKE ?', '%foo bar%')
```

And here is a more complex example.

```ruby
class User < ActiveRecord::Base
  has_many :tasks
end

class Category < ActiveRecord::Base
  has_many :tasks
end

class Task < ActiveRecord::Base
  belongs_to :category
  belongs_to :user
  enum state: [:incomplete, :complete]
end

class TaskSearch < SearchLingo::AbstractSearch
  parser do |token|
    token.match /\Acategory:\s*"?(.*?)"?\z/ do |m|
      [:where, { categories: { name: m[1] } }]
    end
  end

  parser do |token|
    token.match /\Ais:\s*(?<state>(?:in)?complete)\z/ do |m|
      [m[:state].to_sym]
    end
  end

  parser do |token|
    token.match /\A([<>])([[:digit:]]+)\z/ do |m|
      [:where, 'tasks.priority #{m[1]} ?', m[2]]
    end
  end

  def default_parse(token)
    [:where, 'tasks.name LIKE ?', "%#{token}%"]
  end

  def scope
    @scope.includes(:category).references(:category)
  end
end

TaskSearch.new('category: "foo bar" <2 baz is: incomplete', Task).results
# => Task.includes(:category).references(:category)
# ->   .where(categories: { name: 'foo bar' })
# ->   .where('tasks.priority < ?', 2)
# ->   .where('tasks.name LIKE ?', '%baz%')
# ->   .incomplete

TaskSearch.new('category: "foo bar"', User.find(42).tasks).results
# => Task.includes(:category).references(:category)
# ->   .where(user_id: 42)
# ->   .where(categories: { name: 'foo bar' })
```

Create a class which inherits from `SearchLingo::AbstractSearch`. Provide an
implementation of `#default_parse` in that class. Register parsers for specific
types of search tokens using the parser class method.

Instantiate your search class by passing in the query string and the scope on
which to perform the search. Use the `#results` method to compile the search
and return the results.

Take a look at the examples/ directory for more concrete examples.

## How It Works

A search is instantiated with a query string and a search scope (commonly an
ActiveRecord model). The search breaks the query string down into a series of
tokens, and each token is processed by a declared series of parsers. If a
parser succeeds, processing immediately advances to the next token. If none of
the declared parsers succeeds, and the token is compound — that is, the token
is composed of an operator and a term (e.g., `foo: bar`), the token is
simplified and then processed by the declared parsers again. If the second pass
also fails, then the (now simplified) token falls through to the
`#default_parse` method defined by the search class. This method should be
implemented in such a way that it always "succeeds" — always returning a Symbol
or an Array that can be splatted and sent to the search scope.

## Search Classes

Search classes should inherit from `SearchLogic::AbstractSearch`, and they must
provide their own implementation of `#default_parse`. Optionally, a search
class may also use the parse class method to add specialized parsers for
handling tokens that match specific patterns. As each token is processed, the
search class will first run through the specialized parsers. If none of them
succeed, it will fall back on the `#default_parse` method. See the section
"Parsing" for more information on how parsers work and how they should be
structured.

## Tokenization

Queries are comprised of zero or more tokens separated by white space. A token
has a term and an optional operator. (A simple token has no operator; a
compound token does.) A term can be a single word or multiple words joined by
spaces and contained within double quotes. For example `foo` and `"foo bar
baz"` are both single terms. An operator is one or more alphanumeric characters
followed by a colon and zero or more spaces.

    QUERY    := TOKEN*
    TOKEN    := (OPERATOR ':' [[:space:]]*)? TERM
    OPERATOR := [[:alnum:]]+
    TERM     := '"' [^"]* '"' | [[:graph:]]+

The following are all examples of tokens:

* `foo`
* `"foo bar"`
* `foo: bar`
* `foo: "bar baz"`

(If you need a term to equal something that might otherwise be interpreted as
an operator, you can enclose the term in double quotes, e.g., while `foo: bar`
would be interpreted a single compound token, `"foo:" bar` would be treated as
two distinct simple tokens, and `"foo: bar"` would be treated as a single
simple token.)

Tokens are passed to parsers as instances of the SearchLingo::Token class.
SearchLingo::Token provides `#operator` and `#term` methods, but delegates all
other behavior to the String class. Consequently, when writing parsers, you
have the option of either interacting with examining the operator and term
individually or treating the entire token as a String and processing it
yourself. The following would produce identical results:

```ruby
token = SearchLingo::Token.new('foo: "bar baz"')

if token.operator == 'foo' then token.term end   # => 'bar baz'
token.match(/\Afoo:\s*"?(.+?)"?\z/) { |m| m[1] } # => 'bar baz'
```

(Note that `#term` takes care of stripping away quotes from the term.)

## Parsers

Any object that can respond to the `#call` method can be used as a parser. If
the parser succeeds, it should return an Array of arguments that can be sent to
the query object using `#public_send`, e.g., `[:where, { id: 42 }]`. If the
parser fails, it should return a falsey value.

For very simple parsers which need not be reusable, you can pass the parsing
logic to the parser method as a block:

```ruby
class MySearch < SearchLingo::AbstractSearch
  parser do |token|
    token.match /\Aid:[[:space:]]*([[:digit:]]+)\z/ do |m|
      [:where, { id: m[1] }]
    end
  end
end
```

If you want to re-use a parser, you could implement it as a lambda:

```ruby
module Parsers
  ID_PARSER = lambda do |token|
    token.match h/\Aid:[[:space:]]*([[:digit:]]+)\z/ do |m|
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
```

Finally, for the most complicated cases, you could implement parsers as
classes:

```ruby
module Parsers
  class IdParser
    def initialize(table, operator = nil)
      @table = table
      @prefix = /#{operator}:\s*/ if operator
    end

    def call(token)
      token.match /\A#{@prefix}([[:digit:]]+)\z/ do |m|
        [:where, { @table => { id: m[1] } }]
      end
    end
  end
end

class EventSearch < SearchLingo::AbstractSearch
  # matches "42" and adds events.id=42 as a condition
  parser Parsers::IdParser.new Event.table_name

  # matches "category: 42" and adds categories.id as a condition
  parser Parsers::IdParser.new Category.table_name, 'category'
end

class CategorySearch < SearchLingo::AbstractSearch
  parser Parsers::IdParser.new :categories
end
```

### Date Parsers

One of the non-trivial parsing tasks I found myself constantly reimplementing
was searching for records matching a date or a date range. To provide examples
of moderately complex parsers and avoid having to think about this parsing
problem again, I've included several parsers for handling US-formatted dates
and date ranges. They will handle dates formatted as M/D/YYYY, M/D/YY, and M/D.
(For M/D, the year is inferred based on the current year and with the
assumption that the date should always be in the past, i.e., if the current
date is 10 June 2015, `6/9` and `6/10` will be parsed as 9 June 2015 and 10
June 2015, respectively, but `6/11` will be parsed as 11 June *2014*.)
Additionally, there are parsers for handling closed date ranges (e.g.,
`1/1/15-6/30/15`) as well as open-ended date ranges (e.g., `1/1/15-` and
`12/31/15`). Look at the files in `lib/search_lingo/parsers` for more details.

As implemented, the date parsers are US-centric. I would like to work on making
them more flexible when time permits.

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
