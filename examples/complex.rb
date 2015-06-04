class Job < ActiveRecord::Base
  # Assume this model has attributes: :id, :date, :name
end

class Receipt < ActiveRecord::Base
  # Assume this model has attributes: :id, :check_no, :check_date, :post_date, :amount
end

module Parsers
  class IdParser
    def initialize(table)
      @table = table
    end

    def call(token)
      token.match /\Aid:\s*([[:digit:]]+)\z/ do |m|
        [:where, { @table => { id: m[1] } }]
      end
    end
  end
end

class JobSearch < AbstractSearch
  parser Parsers::IdParser.new Job.table_name

  parser SearchLingo::Parsers::DateParser.new Job.table_name,
    :date
  parser SearchLingo::Parsers::DateRangeParser.new Job.table_name,
    :date
  parser SearchLingo::Parsers::LTEDateParser.new Job.table_name,
    :date, connection: Job.connection
  parser SearchLingo::Parsers::GTEDateParser.new Job.table_name,
    :date, connection: Job.connection

  def default_parse(token)
    [:where, 'jobs.name LIKE ?', "%#{token}%"]
  end
end

class ReceiptSearch < AbstractSearch
  parser Parsers::IdParser.new Receipt.table_name

  parser SearchLingo::Parsers::DateParser.new Receipt.table_name,
    :check_date
  parser SearchLingo::Parsers::DateRangeParser.new Receipt.table_name,
    :check_date
  parser SearchLingo::Parsers::LTEDateParser.new Receipt.table_name,
    :check_date, connection: Receipt.connection
  parser SearchLingo::Parsers::GTEDateParser.new Receipt.table_name,
    :check_date, connection: Receipt.connection

  parser SearchLingo::Parsers::DateParser.new Receipt.table_name,
    :post_date, 'posted'
  parser SearchLingo::Parsers::DateRangeParser.new Receipt.table_name,
    :post_date, 'posted'
  parser SearchLingo::Parsers::LTEDateParser.new Receipt.table_name,
    :post_date, 'posted', connection: Receipt.connection
  parser SearchLingo::Parsers::GTEDateParser.new Receipt.table_name,
    :post_date, 'posted', connection: Receipt.connection

  parser do |token|
    token.match /\Aamount: (\d+(?:\.\d+)?)\z/ do |m|
      [:where, { receipts: { amount: m[1] } }]
    end
  end

  def default_parse(token)
    [:where, 'receipts.check_no LIKE ?', token]
  end
end

search = JobSearch.new('6/4/15-6/5/15 id: 42 "foo bar"')
search.results  # =>  Job
                #       .where('jobs' => { date: Date.new(2015, 6, 4)..Date.new(2015, 6, 5) })
                #       .where('jobs' => { id: '42' })
                #       .where('jobs.name LIKE ?', '%foo bar%')

search = ReceiptSearch.new('-6/4/15 posted: 6/5/15- amount: 1000 123')
search.results  # =>  Receipt
                #       .where('"receipts"."check_date" <= ?', Date.new(2015, 6, 4))
                #       .where('"receipts"."post_date" >= ?', Date.new(2015, 6, 5))
                #       .where(receipts: { amount: '1000' })
                #       .where('receipts.check_no LIKE ?', 123)
