require 'minitest_helper'
require 'search_lingo'

class TestSearchLingo < Minitest::Test # :nodoc:
  def test_that_it_has_a_version_number
    refute_nil ::SearchLingo::VERSION
  end
end
