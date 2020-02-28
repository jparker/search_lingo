# frozen-string-literal: true

class Job < ActiveRecord::Base # :nodoc:
  # Attributes:
  #   :id
  #   :date
  #   :name
end

class Receipt < ActiveRecord::Base # :nodoc:
  # Attributes:
  #   :id
  #   :check_no
  #   :check_date
  #   :post_date
  #   :amount
end

module Parsers # :nodoc:
  class IdParser # :nodoc:
    def initialize(table)
      @table = table
    end

    def call(token, chain)
      token.match(/\Aid:\s*([[:digit:]]+)\z/) do |m|
        chain.where @table => { id: m[1] }
      end
    end
  end
end

class JobSearch < SearchLingo::AbstractSearch # :nodoc:
  parser SearchLingo::Parsers::DateParser.new Job.arel_table[:date]
  parser Parsers::IdParser.new Job.table_name

  def default_parse(token, chain)
    chain.where Job.arel_table[:name].matches "%#{token}%"
  end
end

class ReceiptSearch < SearchLingo::AbstractSearch # :nodoc:
  # You might prefer to include SearchLingo::Parsers if you you are going to
  # instantiate multiple DateParsers.
  include SearchLingo::Parsers
  parser DateParser.new Receipt.arel_table[:check_date]
  parser DateParser.new Receipt.arel_table[:post_date], modifier: 'posted'

  parser do |token, chain|
    token.match(/\Aamount: (\d+(?:\.\d+)?)\z/) do |m|
      chain.where receipts: { amount: m[1] }
    end
  end

  def default_parse(token, chain)
    chain.where Receipt.arel_table[:check_no].matches token
  end
end

search = JobSearch.new('6/4/15-6/5/15 id: 42 "foo bar"')
search.results
# => Job
#     .where(Job.arel_table[:date].in(Date.new(2015,6,4)..Date.new(2015,6,5)))
#     .where('jobs' => { id: '42' })
#     .where(Job.arel_table[:name].matches('%foo bar%'))

search = ReceiptSearch.new('-6/4/15 posted: 6/5/15- amount: 1000 123')
search.results
# => Receipt
#     .where(Receipt.arel_table[:check_date].lteq(Date.new(2015, 6, 4)))
#     .where(Receipt.arel_table[:post_date].gteq(Date.new(2015, 6, 5)))
#     .where(receipts: { amount: '1000' })
#     .where(Receipt.arel_table[:check_no].matches('123'))
