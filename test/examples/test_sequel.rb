# frozen-string-literal: true

require 'minitest_helper'
require 'logger'
require 'search_lingo'

require File.expand_path '../../examples/sequel_example', __dir__

class TestSequelSearch < Minitest::Test # :nodoc:
  attr_reader :db

  def setup
    connect_db
    create_tables
    load_seed_data
  end

  def test_default_parser
    search = TaskSearch.new 'two', db[:tasks]
    assert_equal ['two'], search.results.map(:name)
  end

  def test_category_parser
    task_name = Sequel.qualify :tasks, :name
    search = TaskSearch.new 'cat: spanish', db[:tasks]
    assert_equal %w[uno dos], search.results.select(task_name).map(:name)
  end

  def test_priority_parser
    search = TaskSearch.new 'prio<2', db[:tasks]
    assert_equal(%w[one uno], search.results.map { |row| row[:name] })
  end

  def test_due_date_parser
    search = TaskSearch.new '2/1/15', db[:tasks]
    assert_equal %w[two dos], search.results.map(:name)
  end

  def test_multiple_conditions
    task_name = Sequel.qualify :tasks, :name
    search = TaskSearch.new 'cat: english prio>1', db[:tasks]
    assert_equal ['two'], search.results.select(task_name).map(:name)
  end

  def test_implicit_scope_filter
    category_name = Sequel.qualify :categories, :name
    task_name = Sequel.qualify :tasks, :name
    scope = db[:tasks].join(:categories, id: :category_id)
                      .where(category_name => 'spanish')
    search = TaskSearch.new 'prio>1', scope
    assert_equal ['dos'], search.results.select(task_name).map(:name)
  end

  def connect_db
    @db = Sequel.sqlite
    @db.loggers << Logger.new(STDOUT) if ENV['LOG_TO_STDOUT']
  end

  # rubocop:disable Metrics/MethodLength
  def create_tables
    db.create_table :categories do
      primary_key :id
      String :name, null: false, unique: true
    end

    db.create_table :tasks do
      primary_key :id
      foreign_key :category_id, :categories
      String :name, null: false
      Integer :priority, null: false
      Date :due_date, null: false
    end
  end
  # rubocop:enable Metrics/MethodLength

  # rubocop:disable Metrics/MethodLength
  def load_seed_data
    db[:categories].insert(name: 'english').tap do |id|
      db[:tasks].insert category_id: id,
                        name: 'one',
                        priority: 1,
                        due_date: Date.new(2015)
      db[:tasks].insert category_id: id,
                        name: 'two',
                        priority: 2,
                        due_date: Date.new(2015, 2)
    end
    db[:categories].insert(name: 'spanish').tap do |id|
      db[:tasks].insert category_id: id,
                        name: 'uno',
                        priority: 1,
                        due_date: Date.new(2015)
      db[:tasks].insert category_id: id,
                        name: 'dos',
                        priority: 2,
                        due_date: Date.new(2015, 2)
    end
  end
  # rubocop:enable Metrics/MethodLength
end
