$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)

require 'minitest/autorun'
require 'minitest/focus'
require 'pry'

# FYI: minitest-reporters does not work with autotest :(
# https://github.com/kern/minitest-reporters/issues/102
require 'minitest/reporters'
Minitest::Reporters.use! Minitest::Reporters::DefaultReporter.new
