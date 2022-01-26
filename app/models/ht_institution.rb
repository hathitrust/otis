# frozen_string_literal: true

class HTInstitution < ApplicationRecord
  has_one :ht_billing_member, foreign_key: "inst_id"
  accepts_nested_attributes_for :ht_billing_member, update_only: true

  self.primary_key = "inst_id"
  has_many :ht_users, foreign_key: :inst_id, primary_key: :inst_id
  has_many :ht_contacts, foreign_key: :inst_id, primary_key: :inst_id
  has_many :ht_registrations, foreign_key: :inst_id, primary_key: :inst_id
  has_many :ht_logs, -> { HTLog.ht_institution }, foreign_key: :objid, primary_key: :inst_id

  validates :inst_id, presence: true, uniqueness: true
  validates :name, presence: true
  validates :enabled, presence: true

  before_save :set_defaults

  # https://stackoverflow.com/a/57485464
  attribute :enabled, ActiveRecord::Type::Integer.new

  scope :enabled, -> { where("enabled = 1") }
  scope :other, -> { where("enabled != 1") }

  def set_defaults
    self.mapto_inst_id ||= inst_id
    return unless entityID

    self.template ||= "https://___HOST___/Shibboleth.sso/Login?entityID=#{entityID}&target=___TARGET___"
  end

  def set_defaults_for_entity(entity_id, metadata = SAMLMetadata.new(entity_id))
    self.entityID = entity_id
    self.name = metadata.name
    self.domain = metadata.domain
    self.inst_id = metadata.domain_base
    self.mapto_inst_id = metadata.domain_base
    self.allowed_affiliations = "^(member|alum|faculty|staff|student)@(#{metadata.scopes.join("|")})"
  end
end
