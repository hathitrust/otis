# frozen_string_literal: true

# Name and description for type of institution contact
class HTContactType < ApplicationRecord
  self.table_name = "ht_repository.otis_contact_types"
  self.primary_key = "id"

  validates :name, presence: true, uniqueness: true, allow_blank: false
  validates :description, presence: true, allow_blank: false

  has_many :ht_logs, -> { HTLog.ht_contact_type }, foreign_key: :objid, primary_key: :id

  before_destroy :check_contacts, prepend: true

  # These are the built-in contact types that should be available at all times.
  # ETAS is not explicitly used by the Otis code.
  # EA Approver is required in order to keep `ht_users` and `otis_registrations` updated.
  # This need be public only so rspec can see how many types there should be.
  BUILTIN_TYPES = [
    {
      name: "ETAS",
      description: "Emergency Temporary Access Service"
    },
    {
      name: "EA Approver",
      description: "Approver for Elevated Access Registration and Renewal"
    }
  ]

  # Create DB entries for the built-in types if necessary.
  def self.initialize_builtin_types!
    BUILTIN_TYPES.each do |type|
      unless exists?(name: type[:name])
        create(**type)
      end
    end
  end

  # Return `HTContactType` corresponding to "EA Approver"
  def self.ea_approver
    where(name: "EA Approver").first
  end

  private

  def check_contacts
    if HTContact.where(contact_type: id).count.positive?
      errors.add :base, :in_use, name: name
      throw :abort
    end
  end
end
