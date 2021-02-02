# frozen_string_literal: true

# We're not really interested in editing or viewing this table,
# but we want to allow HTUser access to a human-readable version of
# the institution.
class HTInstitution < ApplicationRecord
  self.primary_key = 'inst_id'
  has_many :ht_users, foreign_key: :identity_provider, primary_key: :entityID

  validates :inst_id, presence: true
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

  # defaults_from_metadata
  #
  #   @name = metadata.entity_info(@eid)[:name]
  #
  #     /\b(?<base>[a-z\-]+)\.(?<ext>edu|gov|com|org|net|ac\.uk)/ =~ eid
  #     if(base and ext)
  #       domain_base = base
  #       domain = "#{base}.#{ext}"
  #     end
  #
  #   {
  #    sdrinst: domain_base,
  #    inst_id: domain_base,
  #    mapto_inst_id: domain_base,
  #    grin_instance: nil,
  #    name: name,
  #    template: "https://___HOST___/Shibboleth.sso/Login?entityID=#{eid}&target=___TARGET___",
  #    authtype: "shibboleth",
  #    domain: domain,
  #    us: true,
  #    enabled: false,
  #    orph_agree: false,
  #    entityID: eid,
  #    allowed_affiliations: "^(alum|member|faculty|staff|student)@#{domain}",
  #    emergency_status: nil,
  #    emergency_contact: nil
  #  }
end
