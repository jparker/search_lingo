require 'date'

module SearchLingo
  module Parsers # :nodoc:
    module MDY
      ##
      # Pattern for matching US-formatted date strings.
      #
      # The year may be two or four digits, or it may be omitted.
      US_DATE = %r{(?<m>\d{1,2})/(?<d>\d{1,2})(?:/(?<y>\d{2}\d{2}?))?}

      ##
      # Returns a +Date+ object for the date represented by +term+. Returns
      # +nil+ if +term+ can not be parsed.
      #
      # If the year has two digits, it will be expanded into a four-digit by
      # +Date.parse+.
      #
      # If the year is omitted, it will be inferred using +relative_to+ as a
      # reference date. In this scenario, the resulting date will always be
      # less than or equal to the reference date. If +relative_to+ omitted, it
      # defaults to today's date.
      #
      # Available as both a class method and an instance method.
      def parse(term, relative_to: Date.today)
        term.match /\A#{US_DATE}\z/ do |m|
          return Date.parse "#{m[:y]}/#{m[:m]}/#{m[:d]}" if m[:y]

          day   = Integer(m[:d])
          month = Integer(m[:m])
          year  = if month < relative_to.month || month == relative_to.month && day <= relative_to.day
                    relative_to.year
                  else
                    relative_to.year - 1
                  end

          Date.new year, month, day
        end
      rescue ArgumentError
      end

      module_function :parse
    end
  end
end
