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

  # Look up an contact for display in an ht_users view.
  # Returns `HTContact` or `nil`
  #def self.with(email:)
  #  find_by(email: email)
  #end

  # Add or update based on email and name.
  # Can be triggered by adding or editing a registration, or editing a user.
  def self.add(email:, inst_id:, name:)
    approver = find_by(email: email)
    if approver.nil?
      approver = new(email: email, name: name)
    else
      approver.name = name
      approver.inst_id = inst_id
    end
    approver.save!
    approver
  end
end
