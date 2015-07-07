module SearchLingo
  ##
  # Pattern for matching modifiers within a token.
  MODIFIER = /[[:alnum:]]+/

  ##
  # Pattern for matching terms within a token.
  TERM = /"[^"]+"|[[:graph:]]+/
end
