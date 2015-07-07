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
  def call(token)
    if token.modifier == 'cat'
      [:where, { category__name: token.term }]
    end
  end
end

class TaskSearch < SearchLingo::AbstractSearch # :nodoc:
  parser CategoryParser.new

  parser do |token|
    token.match /\A([<>])([[:digit:]]+)\z/ do |m|
      [:where, ->{ priority.send m[1], m[2] }]
    end
  end

  parser do |token|
    token.match %r{\A(?<m>\d{1,2})/(?<d>\d{1,2})/(?<y>\d{2}\d{2}?)\z} do |m|
      begin
        [:where, { due_date: Date.parse("#{m[:y]}/#{m[:m]}/#{m[:d]}") }]
      rescue ArgumentError
      end
    end
  end

  def default_parse(token)
    [:where, 'tasks.name LIKE ?', "%#{token.term}%"]
  end

  def scope
    @scope.eager_graph(:category)
  end
end
