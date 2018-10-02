require 'sequel'
require 'sqlite3'

DB = Sequel.sqlite

if ENV['LOG_TO_STDOUT']
  require 'logger'
  DB.loggers << Logger.new(STDOUT)
end

DB.create_table :categories do
  primary_key :id
  String :name, null: false, unique: true
end

DB.create_table :tasks do
  foreign_key :category_id, :categories
  String :name, null: false, unique: true
  Integer :priority, null: false
  Date :due_date, null: false
end

class Category < Sequel::Model # :nodoc:
  one_to_many :tasks
end

class Task < Sequel::Model # :nodoc:
  many_to_one :category
end

class CategoryParser # :nodoc:
  def call(token, chain)
    if token.modifier == 'cat'
      chain.eager_graph(:category)
        .where Sequel.qualify('category', 'name') => token.term
    end
  end
end

class TaskSearch < SearchLingo::AbstractSearch # :nodoc:
  parser CategoryParser.new

  # Match categories with priority less than or greater than a given value.
  #
  # <2 => Categories with priority < 2
  # >5 => Categories with priority > 5
  parser do |token, chain|
    token.match /\A([<>])([[:digit:]]+)\z/ do |m|
      chain.eager_graph(:category)
        .where Sequel.expr { priority.send m[1], m[2] }
    end
  end

  # Match tasks with a given due_date.
  #
  # 7/4/1776 => Tasks with due_date == Date.new(1776, 7, 4)
  # 7/4/17   => Tasks with due_date == Date.new(2017, 7, 4)
  parser do |token, chain|
    token.match %r{\A(\d{1,2})/(\d{1,2})/(\d{2}\d{2}?)\z} do |m|
      date = begin
               Date.parse '%d/%d/%d' % m.values_at(3, 1, 2)
             rescue ArgumentError
               return nil
             end
      chain.where due_date: date
    end
  end

  # Match tasks with names that contain a given term.
  #
  # pay bills   => Match tasks with names like "pay bills", "pay bills by today"
  # brush teeth => Match tasks with names like "brush teeth", "brush teeth and floss"
  def default_parse(token, chain)
    chain.where Sequel.lit 'tasks.name LIKE ?', "%#{token.term}%"
  end
end
