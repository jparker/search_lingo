require 'date'

module SearchLingo
  module Parsers
    module MDY
      US_DATE = %r{(?<m>\d{1,2})/(?<d>\d{1,2})(?:/(?<y>\d{2}\d{2}?))?}

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
        # returns nil
      end

      module_function :parse
    end
  end
end
