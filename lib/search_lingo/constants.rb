# frozen-string-literal: true

module SearchLingo
  ##
  # Pattern for matching modifiers within a token.
  MODIFIER = /[[:alnum:]]+/.freeze

  ##
  # Pattern for matching terms within a token.
  TERM = /"[^"]+"|[[:graph:]]+/.freeze
end
