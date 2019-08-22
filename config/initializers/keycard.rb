# frozen_string_literal: true

def assign_db(lhs, rhs)
  if rhs.is_a? String
    lhs.url = rhs
  elsif rhs.respond_to?(:has_key?)
    if rhs["url"]
      lhs.url = rhs["url"]
    else
      lhs.opts = rhs
    end
  end
end

assign_db(Keycard::DB.config, Otis.config.keycard.database)

Keycard::DB.config.readonly = true if Otis.config.keycard&.readonly
Keycard.config.access = Otis.config.keycard&.access || :direct
