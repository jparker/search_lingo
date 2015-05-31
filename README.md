# SearchLingo

SearchLingo is a framework for defining simple, user-friendly query languages
and translating them into their underlying queries.

Although designed originally to be used with simple searches using ActiveRecord
models, there is no dependency on ActiveRecord or Rails. The search classes you
define will provide the query object (commonly an ActiveRecord model or an
ActiveRecord::Relation), and the parsers you define will describe what messages
to send to the query object (typically things like <code>#where</code> or a
named scope) to perform the search.

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

TODO: Write usage instructions here

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
