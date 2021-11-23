# frozen_string_literal: true

# Name and description for type of institution contact
class HTContactType < ApplicationRecord
  validates :name, presence: true, uniqueness: true, allow_blank: false
  validates :description, presence: true, allow_blank: false

  has_many :ht_logs, -> { HTLog.ht_contact_type }, foreign_key: :objid, primary_key: :id

  before_destroy :check_contacts, prepend: true

  self.primary_key = "id"

  private

  def check_contacts
    if HTContact.where(contact_type: id).count.positive?
      errors.add(:base, "Contact type is in use")
      throw :abort
    end
  end
end
