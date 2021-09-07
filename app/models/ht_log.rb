# frozen_string_literal: true

class HTLog < ApplicationRecord
  validates :model, presence: true
  validates :objid, presence: true
  validates :data, presence: true

  serialize :data, JSON
  attribute :time, default: -> { Time.zone.now }

  default_scope { order(:time) }
  scope :ht_contact, -> { where(model: :HTContact).order("time") }
  scope :ht_contact_type, -> { where(model: :HTContactType).order("time") }
  scope :ht_institution, -> { where(model: :HTInstitution).order("time") }
  scope :ht_user, -> { where(model: :HTUser).order("time") }
end
