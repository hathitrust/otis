# frozen_string_literal: true

# Map of institution email contact and type
class HTContact < ApplicationRecord
  self.table_name = "ht_repository.otis_contacts"
  self.primary_key = "id"

  belongs_to :ht_institution, foreign_key: :inst_id, primary_key: :inst_id, required: true
  belongs_to :ht_contact_type, foreign_key: :contact_type, primary_key: :id, required: true
  scope :for_institution, ->(inst_id) { where(inst_id: inst_id).order(:contact_type) }

  has_many :ht_logs, -> { HTLog.ht_contact }, foreign_key: :objid, primary_key: :id

  validates :inst_id, presence: true
  validates :contact_type, presence: true
  validates :email, presence: true, format: {with: URI::MailTo::EMAIL_REGEXP}
  validates :name, presence: true

  # Add or update based on email and contact type id.
  # Can be triggered by adding or editing a registration, or editing a user.
  # Use `tap` instead of passing a block to `find_or_initialize_by` because we want
  # to update name and institution even if record already exists. (Although they are
  # unlikely to change substantially, new registration data should probably override
  # old.
  def self.add_or_update(contact_type:, email:, inst_id:, name:)
    find_or_initialize_by(email: email, contact_type: contact_type).tap do |approver|
      approver.inst_id = inst_id
      approver.name = name
      approver.save!
    end
  end
end
