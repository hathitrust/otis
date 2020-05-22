# frozen_string_literal: true

class HTUserLog < ApplicationRecord
  belongs_to :ht_user, foreign_key: :userid, primary_key: :userid

  validates :userid, presence: true
  validates :data, presence: true

  serialize :data, JSON

  attribute :time, default: -> { Time.zone.now }
end
