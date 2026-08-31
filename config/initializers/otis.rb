# frozen_string_literal: true

#require "rails"
#require "app/models/ht_contact_type"

# Otis needs ETAS and EA Approver contact types
Rails.application.config.to_prepare do
  HTContactType.initialize_builtin_types
end
