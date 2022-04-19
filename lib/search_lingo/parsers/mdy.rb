# frozen-string-literal: true

require 'date'

module SearchLingo
  module Parsers # :nodoc:
    ##
    # MDY provides a parser for dates that adhere to the MDY format used in the
    # US.
    module MDY
      ##
      # Pattern for matching US-formatted date strings.
      #
      # The year may be two or four digits, or it may be omitted.
      US_DATE = %r{(?<m>\d{1,2})/(?<d>\d{1,2})(?:/(?<y>\d{2}\d{2}?))?}.freeze

      ##
      # Returns a +Date+ object for the date represented by +term+. Returns
      # +nil+ if +term+ can not be parsed.
      #
      # If the year has two digits, it will be implicitly expanded into a
      # four-digit year by +Date.parse+. Otherwise it will be used as is.
      #
      # If the year is omitted, it will be inferred using +relative_to+ as a
      # reference date. In this scenario, the resulting date will always be
      # less than or equal to the reference date. If +relative_to+ omitted, it
      # defaults to today's date.
      #
      # Available as both a class method and an instance method.
      # rubocop:disable Metrics/MethodLength
      def parse(term, relative_to: Date.today)
        term.match(/\A#{US_DATE}\z/) do |m|
          return Date.parse "#{m[:y]}/#{m[:m]}/#{m[:d]}" if m[:y]

          ref   = relative_to
          month = Integer m[:m]
          day   = Integer m[:d]
          year  = if month < ref.month || (month == ref.month && day <= ref.day)
                    ref.year
                  else
                    ref.year - 1
                  end
          Date.new year, month, day
        end
      rescue ArgumentError
        # Fail if Date.parse or Date.new raise ArgumentError.
        nil
      end
      # rubocop:enable Metrics/MethodLength

      module_function :parse
    end
  end
end
