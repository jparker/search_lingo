module SearchLingo
  ##
  # Pattern for matching modifiers within a token.
  OPERATOR  = /[[:alnum:]]+/

  ##
  # Pattern for matching terms within a token.
  TERM      = /"[^"]+"|[[:graph:]]+/
end
