# frozen_string_literal: true

# Only used read-only in OTIS, to decorate ht_user views with additional access info
class HTCount < ApplicationRecord
  self.primary_key = 'userid'
  belongs_to :ht_user, foreign_key: :userid, primary_key: :userid
end
