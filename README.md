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

## Upgading

Version 2 introduces a breaking change to the parsing workflow. In older
versions, parsers were sent one argument (the token), and were expected to
return an array that would be sent to the scope using `#public_send`. The new
version sends the token and the filter chain to the parsers, and they are
expected to append methods to the filter chain and return the result. This
change makes it possible for parsers to make more than one addition to the
filter chain.

After upgrading, your parsers should be upgraded as follows:

```ruby
# Before
parser do |token|
  if token.modifier == 'something'
    [:where, { column: token.term }]
  end
end

# After
parser do |token, chain|
  if token.modifier == 'something'
    chain.where column: token.term
  end
end
```

Similar changes will need to be made to your `#default_parse` implementation.

```ruby
# Before
def default_parse(token)
  [:where, { column: token }]
end

# After
def default_parse(token, chain)
  chain.where column: token
end
```

If you provided your own implementation of `#scope` in your search class to
ensure that certain relations were joined, you may want to revisit the decision
in case the joins can be added only if needed by a particular parser.

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

Concrete examples of how to use this gem are provided in `examples/` and
`test/examples/`, but here is a simple example.

```ruby
class Task < ActiveRecord::Base
end

class TaskSearch < SearchLingo::AbstractSearch
  def default_parse(token, chain)
    chain.where 'name LIKE ?', "%#{token}%"
  end
end

TaskSearch.new('foo bar', Task.all).results
# => Task.where('name LIKE ?', '%foo%').where('name LIKE ?', '%bar%')

TaskSearch.new('"foo bar"', Task.all).results
# => Task.where('name LIKE ?', '%foo bar%')
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
  enum state: %i[incomplete complete]
end

class TaskSearch < SearchLingo::AbstractSearch
  parser do |token, chain|
    token.match(/\Ais:\s*(?<state>(?:in)?complete)\z/) do |m|
      # Appends a named scope defined by `enum` to filter chain
      chain.public_send m[:state].to_sym
    end
  end

  parser do |token, chain|
    if token.modifier == 'cat'
      # Appends a join and a where clause to the filter chain.
      chain.joins(:category).where categories: { name: token.term }
    end
  end

  parser do |token, chain|
    token.match(/\A(?<op>[<>])(?<prio>[[:digit:]]+)\z/) do |m|
      priority = Task.arel_table[:priority]
      if m[:op] == '<'
        chain.where priority.lt m[:prio]
      else
        chain.where priority.gt m[:prio]
      end
    end
  end

  def default_parse(token, chain)
    chain.where Task.arel_table[:name].matches "%#{token}%"
  end
end

TaskSearch.new('cat: foo <2 "bar baz" is: incomplete', Task.all).results
# => Task.all
# ->   .joins(:category)
# ->   .where(categories: { name: 'foo' })
# ->   .where(Task.arel_table[:priority].gt(2))
# ->   .where(Task.arel_table[:name].matches('%bar baz%'))
# ->   .incomplete

user = User.find 42
TaskSearch.new('is: complete "foo bar"', user.tasks).results
# => user.tasks.complete.where(Task.arel_table[:name].matches('%foo bar%'))
```

A search class should inherit from `SearchLingo::AbstractSearch`, and it should
provide its own implementation of `#default_parse`. Register additional parsers
with `.parser` as needed.

Instantiate your search class with a query string and the scope on which to
search. Send that instance `#results` to compile and execute the search and
return the results.

## How It Works

A search is instantiated with a query string and a search scope (such as an
ActiveRecord model). The search breaks the query string down into a series of
tokens and parses them, composing the search query by chaining method calls
onto the initial search scope.

A search class registers zero or more special-case parsers. Processing of each
token runs through the parsers in the order in which they were registered.
Parsing of a single token halts when a parser succeeds. When a parser succeeds,
it should append to the search scope a method call which implements the filter
for the given token. When a parser fails, it should return a `nil` or `false`.

If all of the registered parsers fail, and the token is compound, it is
simplified and reprocessed by the same set of parsers (see "Tokenization" for
more information).

If still no parser has successfully parsed the token, it falls back on the
`#default_parse`.

## Search Classes

Search classes should inherit from `SearchLingo::AbstractSearch`. They must
provide their own implementation of `#default_parse` which should probably, at
a minimum, return the current filter chain. Custom parsers can be registered
with the `.parser` class method. Custom parsers are tried in the same order in
which they are defined. Bear this in mind when defining parsers.

## Tokenization

Queries are comprised of zero or more tokens separated by white space. A token
is an optional modifier followed by a term. A modifier is one or more
alphanumeric characters and is followed by a colon. A term can be a single word
or multiple words contained within double quotes (both `foo` and `"foo bar
baz"` are valid single terms).

    QUERY    := TOKEN*
    TOKEN    := (MODIFIER ':' [[:space:]]*)? TERM
    MODIFIER := [[:alnum:]]+
    TERM     := '"' [^"]* '"' | [[:graph:]]+

The following are all examples of tokens:

* `foo`
* `"foo bar"`
* `foo: bar`
* `foo: "bar baz"`

(If you need a term to equal something that might otherwise be interpreted as
a modifier, you can enclose the term in double quotes, e.g., while `foo: bar`
would be interpreted a single compound token, `"foo:" bar` would be treated as
two distinct simple tokens, and `"foo: bar"` would be treated as a single
simple token.)

Tokens are passed to parsers as instances of the `SearchLingo::Token` class.
`SearchLingo::Token` provides `#modifier` and `#term` methods, but delegates
all other behavior to the String class. Consequently, when writing parsers, you
have the option of either interacting with examining the modifier and term
individually or treating the entire token as a String and processing it
yourself. The following would produce identical results:

```ruby
token = SearchLingo::Token.new('foo: "bar baz"')

if token.modifier == 'foo' then token.term end   # => 'bar baz'
token.match(/\Afoo:\s*"?(.+?)"?\z/) { |m| m[1] } # => 'bar baz'
```

(Note that `#term` takes care of stripping away quotes from the term.)

## Parsers

Any object that responds to `#call` can be used as a parser. It will be sent
two arguments: the token and the current filter chain. If a parser succeeds, it
should append one or more methods to the filter chain and return the result. If
a parser fails, it should return a falsey value (usually `nil`).

For very simple parsers which need not be reusable, you can pass the parsing
logic to the parser method as a block:

```ruby
class MySearch < SearchLingo::AbstractSearch
  parser do |token, chain|
    token.match(/\Aid:[[:space:]]*([[:digit:]]+)\z/) do |m|
      chain.where id: m[1]
    end
  end
end
```

If you want to re-use a parser, you could implement it as a lambda:

```ruby
module Parsers
  ID_PARSER = lambda do |token, chain|
    token.match(/\Aid:[[:space:]]*([[:digit:]]+)\z/) do |m|
      chain.where id: m[1]
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

For more complex cases, you may choose to implement a parser as its own class.

```ruby
module Parsers
  class DateParser
    US_DATE = %r{(?<m>\d{1,2})/(?<d>\d{1,2})/(?<y>\d{4})}

    attr_reader :column

    def initialize(column)
      @column = column
    end

    def call(token, chain)
      catch :halt do
        parse_simple_date token, chain
        parse_date_range token, chain
        parse_open_date_range token, chain
      end
    end

    private

    # Parses simple dates like "10/2/2018"
    def parse_simple_date(token, chain)
      token.match(/\A#{US_DATE}\z/) do |m|
        date = Date.parse '%04d-%02d-%02d' % m.values_at(:y, :m, :d)
        throw :halt, chain.where(column.eq(date))
      end
    rescue ArgumentError
      # Raised by Date.parse for invalid dates
    end

    # Parses date ranges like "10/1/2018-10/31/2018"
    def parse_date_range(token, chain)
      token.match(/\A#{US_DATE}-#{US_DATE}\z/) do |m|
        min = Date.parse '%04d-%02d-%02d' % m.values_at(3, 1, 2)
        max = Date.parse '%04d-%02d-%02d' % m.values_at(6, 4, 3)
        throw :halt, chain.where(column.in(min..max))
      end
    rescue ArgumentError
      # Raised by Date.parse for invalid dates
    end

    # Parses open-ended date ranges like "10/1/2018-" or "-10/31/2018"
    def parse_open_date_range(token, chain)
      token.match(/\A(?<min>#{US_DATE})-|-(?<max>#{US_DATE})\z) do |m|
        if m[:min]
          date = Date.parse '%04d-%02d-%02d' % m.values_at(:y, :m, :d)
          throw :halt, chain.where(column.gteq(date))
        else
          date = Date.parse '%04d-%02d-%02d' % m.values_at(:y, :m, :d)
          throw :halt, chain.where(column.lteq(date))
        end
      end
    rescue ArgumentError
      # Raised by Date.pares for invalid dates
    end
  end
end

class EventSearch < SearchLingo::AbstractSearch
  parser Parsers::DateParser.new
end
```

(Date parsing was a convenient example of a parser complex enough to warrant
its own class, but a date parser is included with the gem. See "Date Parsers"
below for more information.)

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

The date parser are specifically designed to work with US-formatted dates. Time
permitting, I will work on making them more flexible.

As implemented they generate queries using AREL. In the future, we should try
generalizing this behavior to also support Sequel for generating queries.

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
