# frozen_string_literal: true

class HTUser < ApplicationRecord
  self.primary_key = 'email'
  belongs_to :ht_institution, foreign_key: :identity_provider, primary_key: :entityID

  validates :iprestrict, presence: true, unless: :mfa
  validates :iprestrict, allow_nil: true,
                         format: {with: /\A(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\z/,
                                  message: 'requires a valid IPv4 address' }

  validates :email, presence: true
  validates :userid, presence: true
  validates :expires, presence: true
  validates :identity_provider, presence: true

  scope :active, -> { where('expires > CURRENT_TIMESTAMP') }
  scope :expired, -> { where('expires <= CURRENT_TIMESTAMP') }

  validate do
    DateTime.parse(expires.to_s)
  rescue StandardError
    errors[:expires] << 'must be a valid timestamp'
  end

  HUMANIZED_ATTRIBUTES = {
    iprestrict: 'IP Restriction'
  }.freeze

  def self.human_attribute_name(attr, options = {})
    HUMANIZED_ATTRIBUTES[attr.to_sym] || super
  end

  # iprestrict is in the database as an escaped IPv4 regex e.g., ^127\.0\.0\.1$
  # For the UI we strip out and restore the ^/./$ characters
  def iprestrict
    escaped = self[:iprestrict]
    return escaped if escaped.nil?

    escaped.gsub(/^\^/, '').gsub(/\$$/, '').gsub(/\\\./, '.')
  end

  def iprestrict=(val)
    val = nil if val.blank?
    val = '^' + val.strip.gsub('.', '\.') + '$' if val.present?
    write_attribute(:iprestrict, val)
  end

  # Display datetime without UTC suffix or just date
  def expires(short: false)
    short ? self[:expires]&.strftime('%Y-%m-%d') : self[:expires]&.to_s(:db)
  end

  # How many days until expiration?
  # @return [Number] days until expiration
  def days_until_expiration
    (self[:expires].to_date - Date.today).to_i
  end

  # Is this person expiring "soon" (based on the config)?
  # @return [Boolean]
  def expiring_soon?
    days_until_expiration.between? 0, (Otis.config&.expires_soon_in_days || 30)
  end

  # Is this person, in fact, expired?
  def expired?
    days_until_expiration.negative?
  end

  def institution
    ht_institution&.name
  end
end
