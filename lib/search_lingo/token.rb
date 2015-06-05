require 'delegate'

module SearchLingo
  class Token < DelegateClass(String)
    FORMAT = %r{\A(?:(\S+):\s*)?"?(.+?)"?\z}

    def operator
      self[FORMAT, 1]
    end

    def term
      self[FORMAT, 2]
    end

    def compound?
      !!operator
    end

    def inspect
      '#<%s String(%s) operator=%s term=%s>' %
        [self.class, super, operator.inspect, term.inspect]
    end
  end
end
