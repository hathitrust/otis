# frozen_string_literal: true

class HTLog < ApplicationRecord
  self.table_name = "ht_web.otis_logs"

  validates :model, presence: true
  validates :objid, presence: true
  validates :data, presence: true

  serialize :data, coder: JSON
  attribute :time, default: -> { Time.zone.now }

  default_scope { order(:time) }
  scope :ht_contact, -> { where(model: :HTContact).order("time") }
  scope :ht_contact_type, -> { where(model: :HTContactType).order("time") }
  scope :ht_institution, -> { where(model: :HTInstitution).order("time") }
  scope :ht_user, -> { where(model: :HTUser).order("time") }
  scope :ht_registration, -> { where(model: :HTRegistration).order("time") }
end
