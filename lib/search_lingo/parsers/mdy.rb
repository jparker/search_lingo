# frozen-string-literal: true

require 'date'

module SearchLingo
  module Parsers # :nodoc:
    ##
    # MDY provides a parser for dates that adhere to the M/D/Y format used in
    # the US.
    module MDY
      ##
      # Pattern for matching US-formatted date strings.
      #
      # The year may be two or four digits, or it may be omitted.
      US_DATE = %r{(?<m>\d{1,2})/(?<d>\d{1,2})(?:/(?<y>\d{2}\d{2}?))?}.freeze

      module_function

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
      # defaults to +Date.today+.
      #
      # Available as both a class method and an instance method.
      def parse(term, relative_to: Date.today)
        term.match(/\A#{US_DATE}\z/) do |m|
          date = reformat_date m, relative_to
          Date.parse date
        end
      rescue ArgumentError
        # Fail if Date.parse or Date.new raise ArgumentError.
        nil
      end

      def reformat_date(match, today) # :nodoc:
        return match.values_at(:y, :m, :d).join('/') if match[:y]

        month = Integer match[:m]
        day = Integer match[:d]
        year = if month < today.month || (month == today.month && day <= today.day)
                 today.year
               else
                 today.year - 1
               end

        "#{year}/#{month}/#{day}"
      end
    end
  end
end
