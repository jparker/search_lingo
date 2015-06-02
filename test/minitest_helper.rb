$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)

require 'minitest/autorun'
require 'minitest/focus'

class Minitest::Test
  def dummy_connection
    DummyConnection.new
  end
end

class DummyConnection
  def quote_column_name(name)
    "\"#{name}\""
  end

  def quote_table_name(name)
    "\"#{name}\""
  end
end
