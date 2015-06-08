require 'delegate'
require 'search_lingo/constants'

module SearchLingo
  class Token < DelegateClass(String)
    STRUCTURE = /\A(?:(#{OPERATOR}):[[:space:]]*)?"?(.+?)"?\z/

    def operator
      self[STRUCTURE, 1]
    end

    def term
      self[STRUCTURE, 2]
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
