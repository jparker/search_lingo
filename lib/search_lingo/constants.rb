# frozen-string-literal: true

module SearchLingo
  ##
  # Pattern for matching modifiers within a token.
  MODIFIER = /[[:alnum:]]+/.freeze

  ##
  # Pattern for matching a simple token.
  SIMPLE_TOKEN = /"[^"]+"|[[:graph:]]+/.freeze

  ##
  # Pattern for matching a simple or compound token.
  SIMPLE_OR_COMPOUND_TOKEN = /(?:#{MODIFIER}:[[:space:]]*)?#{SIMPLE_TOKEN}/.freeze

  ##
  # Pattern for matching a simple or compound token, with regex grouping to aid
  # in decomposing the token into its modifier and term components.
  SIMPLE_OR_COMPOUND_TOKEN_WITH_GROUPING = /\A(?:(#{MODIFIER}):[[:space:]]*)?(#{SIMPLE_TOKEN})\z/.freeze

  ##
  # Pattern for matching the delimiter between tokens.
  DELIMITER = /[[:space:]]*/.freeze
end
