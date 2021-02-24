# frozen_string_literal: true

class HTInstitutionLog < ApplicationRecord
  belongs_to :ht_institution, foreign_key: :inst_id, primary_key: :inst_id

  validates :inst_id, presence: true
  validates :data, presence: true

  serialize :data, JSON

  attribute :time, default: -> { Time.zone.now }
end
