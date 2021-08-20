# frozen_string_literal: true

# Name and description for type of institution contact
class HTContactType < ApplicationRecord
  validates :name, presence: true, uniqueness: true, allow_blank: false
  validates :description, presence: true, allow_blank: false

  before_destroy :check_contacts, prepend: true

  # Checkpoint
  def resource_type
    :ht_contact_type
  end

  def resource_id
    id
  end

  private

  def check_contacts
    if HTContact.where(contact_type: id).count.positive?
      errors.add(:base, "Contact type is in use")
      throw :abort
    end
  end
end
