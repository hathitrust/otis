# frozen_string_literal: true

# We're not really interested in editing or viewing this table,
# but we want to allow HTUser access to a human-readable version of
# the institution.
class HTInstitution < ApplicationRecord
  self.primary_key = 'sdrinst'
  has_many :ht_users, foreign_key: :identity_provider, primary_key: :entityID
end
