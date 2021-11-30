# frozen_string_literal: true

class OtisLog < ApplicationRecord
  validates :model, presence: true
  validates :objid, presence: true
  validates :data, presence: true

  serialize :data, JSON
  attribute :time, default: -> { Time.zone.now }

  default_scope { order(:time) }
  scope :contact, -> { where(model: :Contact).order("time") }
  scope :contact_type, -> { where(model: :ContactType).order("time") }
  scope :ht_institution, -> { where(model: :HTInstitution).order("time") }
  scope :ht_user, -> { where(model: :HTUser).order("time") }
  scope :registration, -> { where(model: :Registration).order("time") }
end
