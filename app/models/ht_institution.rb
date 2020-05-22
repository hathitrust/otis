# frozen_string_literal: true

# We're not really interested in editing or viewing this table,
# but we want to allow HTUser access to a human-readable version of
# the institution.
class HTInstitution < ApplicationRecord
  self.primary_key = 'inst_id'
  has_many :ht_users, foreign_key: :identity_provider, primary_key: :entityID

  scope :enabled, -> { where('enabled = 1') }
  scope :disabled, -> { where('enabled != 1') }
end
