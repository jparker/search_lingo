require 'minitest_helper'
require 'search_lingo'

require File.expand_path File.join('..', 'examples', 'sequel_example'), __dir__

class TestSequelSearch < Minitest::Test
  def setup
    @en = Category.create(name: 'english').tap do |cat|
      cat.add_task name: 'one', priority: 1, due_date: Date.new(2015, 1)
      cat.add_task name: 'two', priority: 2, due_date: Date.new(2015, 2)
    end

    @es = Category.create(name: 'spanish').tap do |cat|
      cat.add_task name: 'uno', priority: 1, due_date: Date.new(2015, 1)
      cat.add_task name: 'dos', priority: 2, due_date: Date.new(2015, 2)
    end
  end

  def teardown
    Task.truncate
    Category.truncate
  end

  def test_default_parser
    search = TaskSearch.new 'two', Task
    assert_equal ['two'], search.results.map { |row| row[:name] }
  end

  def test_category_parser
    search = TaskSearch.new 'cat: spanish', Task
    assert_equal %w[uno dos], search.results.map { |row| row[:name] }
  end

  def test_priority_parser
    search = TaskSearch.new '<2', Task
    assert_equal %w[one uno], search.results.map { |row| row[:name] }
  end

  def test_due_date_parser
    search = TaskSearch.new '2/1/15', Task
    assert_equal %w[two dos], search.results.map { |row| row[:name] }
  end

  def test_multiple_conditions
    search = TaskSearch.new 'cat: english >1', Task
    assert_equal ['two'], search.results.map { |row| row[:name] }
  end

  def test_implicit_scope_filter
    skip "I don't yet understand Sequel associations well enough to get this working."
    search = TaskSearch.new '>1', @es.tasks
    assert_equal ['dos'], search.results.map { |row| row[:name] }
  end
end
