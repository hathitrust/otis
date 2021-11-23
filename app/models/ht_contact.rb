# frozen_string_literal: true

# Map of institution email contact and type
class HTContact < ApplicationRecord
  belongs_to :ht_institution, foreign_key: :inst_id, primary_key: :inst_id, required: true
  belongs_to :ht_contact_type, foreign_key: :contact_type, primary_key: :id, required: true
  scope :for_institution, ->(inst_id) { where(inst_id: inst_id).order(:contact_type) }

  has_many :ht_logs, -> { HTLog.ht_contact }, foreign_key: :objid, primary_key: :id

  validates :inst_id, presence: true
  validates :contact_type, presence: true
  validates :email, presence: true, format: {with: URI::MailTo::EMAIL_REGEXP}

  self.primary_key = "id"

  def institution
    HTInstitution.find(self[:inst_id])
  end
end
