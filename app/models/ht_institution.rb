# frozen_string_literal: true

# We're not really interested in editing or viewing this table,
# but we want to allow HTUser access to a human-readable version of
# the institution.
class HTInstitution < ApplicationRecord
  self.primary_key = 'inst_id'
  has_many :ht_users, foreign_key: :identity_provider, primary_key: :entityID

  validates :inst_id, presence: true, uniqueness: true
  validates :name, presence: true
  validates :enabled, presence: true

  before_save :set_defaults

  # https://stackoverflow.com/a/57485464
  attribute :enabled, ActiveRecord::Type::Integer.new

  scope :enabled, -> { where('enabled = 1') }
  scope :other, -> { where('enabled != 1') }

  # Checkpoint
  def resource_type
    :ht_institution
  end

  def resource_id
    id
  end

  def set_defaults
    self.sdrinst ||= inst_id
    self.mapto_inst_id ||= inst_id
    self.orph_agree ||= false

    if entityID
      self.template ||= "https://___HOST___/Shibboleth.sso/Login?entityID=#{entityID}&target=___TARGET___"
      self.authtype ||= "shibboleth"
    end
  end

  def set_defaults_for_entity(entityID,metadata=SAMLMetadata.new(entityID))
    self.entityID = entityID
    self.name = metadata.name
    self.domain = metadata.domain
    self.inst_id = metadata.domain_base
    self.mapto_inst_id = metadata.domain_base
    self.allowed_affiliations = "^(member|alum)@(#{metadata.scopes.join('|')})"
  end
end
