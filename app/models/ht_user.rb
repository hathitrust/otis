# frozen_string_literal: true

class HTUser < ApplicationRecord
  # Validates IPv4 with ^, $, and . escaped.
  def self.ip_address_regex
    /\A\^(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\$\z/
  end

  self.primary_key = 'email'
  belongs_to :ht_institution, foreign_key: :identity_provider, primary_key: :entityID

  validates :iprestrict, presence: true, unless: :mfa
  validate :validate_iprestrict_format

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
  # Since multiple addresses are permitted if separated by OR (|) this value is
  # an array.
  def iprestrict
    escaped = self[:iprestrict]
    return nil if escaped.nil?

    escaped.split('|').map do |esc|
      esc.gsub(/^\^/, '').gsub(/\$$/, '').gsub(/\\\./, '.')
    end
  end

  def iprestrict=(vals)
    escaped = nil
    if vals.present?
      escaped = vals.split(/\s*,\s*/).map do |val|
        '^' + val.strip.gsub('.', '\.') + '$'
      end.join('|')
    end
    write_attribute(:iprestrict, escaped)
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

  # Validate the fully-escaped ip address(es) as saved in the model.
  def validate_iprestrict_format
    return unless self[:iprestrict].present?

    self[:iprestrict].split('|').each do |ip|
      unless ip.match? HTUser.ip_address_regex
        errors.add :iprestrict, I18n.t('activerecord.errors.models.HTUser.attributes.iprestrict')
        break
      end
    end
  end
end
