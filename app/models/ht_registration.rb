# frozen_string_literal: true

class HTRegistration < ApplicationRecord
  self.primary_key = "id"
  self.table_name = "ht_web.otis_registrations"
  # FIXME: the roles in HTUser are expected to be simplified to look more like this.
  # Once that happens this list should be replaced with the one from HTUser
  ROLES = %i[crms quality resource_sharing ssd ssdproxy staffdeveloper].freeze

  def self.expiration_date
    Date.today - 1.week
  end

  def self.digest(tok)
    Digest::SHA256.base64digest(Base64.decode64(tok))
  end

  def self.find_by_token(tok)
    find_by_token_hash(digest(tok))
  end

  belongs_to :ht_institution, foreign_key: :inst_id, primary_key: :inst_id, required: true
  has_many :ht_logs, -> { HTLog.ht_registration }, foreign_key: :objid, primary_key: :id

  validates :id, uniqueness: true
  validates :inst_id, presence: true
  validates :role, presence: true
  validates :expire_type, presence: true

  # auth_rep = authorized representative
  validates :auth_rep_name, presence: true
  validates :auth_rep_email, presence: true, format: {with: URI::MailTo::EMAIL_REGEXP}
  validates :auth_rep_date, presence: true

  validates :applicant_name, presence: true
  validates :applicant_email, presence: true, format: {with: URI::MailTo::EMAIL_REGEXP}
  validates :applicant_date, presence: true

  validates :token_hash, presence: true, if: :sent
  validates :contact_info, allow_blank: true, format: {with: URI::MailTo::EMAIL_REGEXP}

  # HathiTrust-level authorizer is only required for non-ATRS users.
  validates :hathitrust_authorizer, presence: true, if: ->(reg) { !["ssd", "ssdproxy"].include? reg.role }

  # mfa = multi factor authentication
  validates_inclusion_of :mfa_addendum, in: [true, false]

  scope :expired, -> { where("received IS NULL AND sent<?", expiration_date.to_s) }
  scope :ready, -> { where("received IS NOT NULL AND finished IS NULL") }

  # This is the bit that goes to the applicant, just a gob of b64 data acting as a 'password'
  def token
    @token ||= SecureRandom.urlsafe_base64 16
  end

  def sent=(value)
    self[:sent] = value
    self[:token_hash] = self.class.digest(token)
  end

  # Registrations are good for a week once the e-mail is sent.
  def expired?
    sent? && self[:sent] < HTRegistration.expiration_date
  end

  def sent?
    self[:sent].present?
  end

  def received?
    self[:received].present?
  end

  def finished?
    self[:finished].present?
  end

  def env
    @env ||= begin
      JSON.parse self[:env]
    rescue => _e
      {}
    end
  end

  def existing_user
    HTUser.where(email: applicant_email).first
  end

  def resource_id
    id
  end

  def resource_type
    :ht_registration
  end
end
