# frozen_string_literal: true

class HTRegistration < ApplicationRecord
  self.primary_key = "id"
  self.table_name = "otis_registrations"

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
  validates :jira_ticket, presence: true
  validates :inst_id, presence: true

  # auth_rep = authorized representative
  validates :auth_rep_name, presence: true
  validates :auth_rep_email, presence: true, format: {with: URI::MailTo::EMAIL_REGEXP}
  validates :auth_rep_date, presence: true

  # dsp = disability service provider
  validates :dsp_name, presence: true
  validates :dsp_email, presence: true, format: {with: URI::MailTo::EMAIL_REGEXP}
  validates :dsp_date, presence: true

  # mfa = multi factor authentication
  validates :mfa_addendum, presence: true
  validates :token_hash, presence: true, if: :sent

  validates :contact_info, allow_blank: true, format: {with: URI::MailTo::EMAIL_REGEXP}

  # This is the bit that goes to the DSP, just a gob of b64 data acting as a 'password'
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

  # Since not currently stored as a Boolean, checking value can be tricky.
  def mfa_addendum?
    self[:mfa_addendum] == "1"
  end

  def resource_id
    id
  end

  def resource_type
    :ht_registration
  end
end
