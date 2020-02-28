# frozen-string-literal: true

require 'sequel'
require 'sqlite3'

# DB = Sequel.sqlite
#
# DB.create_table :categories do
#   primary_key :id
#   String :name, null: false, unique: true
# end
#
# DB.create_table :tasks do
#   foreign_key :category_id, :categories
#   String :name, null: false, unique: true
#   Integer :priority, null: false
#   Date :due_date, null: false
# end

class CategoryParser # :nodoc:
  def call(token, chain)
    return nil unless token.modifier == 'cat'

    # This is not an ideal example. Sequel will join the categories table for
    # each token that matches. I'm ignoring the problem since this is only an
    # example.
    category_name = Sequel.qualify :categories, :name
    chain.join(:categories, id: :category_id).where category_name => token.term
  end
end

class TaskSearch < SearchLingo::AbstractSearch # :nodoc:
  parser CategoryParser.new

  # Match tasks with matching priority
  #
  # prio<2 => Tasks with priority less than 2
  # prio>2 => Tasks with priority greater than 2
  # prio=2 => Tasks with priority equal to 5
  parser do |token, chain|
    token.match(/\A prio ([<=>]) (\d+) \z/x) do |m|
      case m[1]
      when '<'
        chain.where { priority <  m[2] }
      when '>'
        chain.where { priority >  m[2] }
      else
        chain.where { priority =~ m[2] }
      end
    end
  end

  # Match tasks with a given due_date.
  #
  # 7/4/1776 => Tasks with due_date == Date.new(1776, 7, 4)
  # 7/4/17   => Tasks with due_date == Date.new(2017, 7, 4)
  parser do |token, chain|
    token.match %r{\A(?<m>\d{1,2})/(?<d>\d{1,2})/(?<y>\d{2}\d{2}?)\z} do |m|
      date = Date.parse "#{m[:y]}/#{m[:m]}/#{m[:d]}"
      chain.where due_date: date
    rescue ArgumentError
      # Fail if Date.parse raises an ArgumentError
      nil
    end
  end

  # Match tasks with names containing the given string.
  def default_parse(token, chain)
    chain.where { name.like "%#{token.term}%" }
  end
end
