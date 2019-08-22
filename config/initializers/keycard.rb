# frozen_string_literal: true

if Otis.config.keycard&.database
  Keycard::DB.config.opts = Otis.config.keycard.database
end

Keycard::DB.config.readonly = true if Otis.config.keycard&.readonly
Keycard.config.access = Otis.config.keycard&.access || :direct
