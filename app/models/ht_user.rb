# frozen_string_literal: true

require 'expiration_date'
require 'forwardable'

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

  validates :mfa, absence: true, unless: -> { ht_institution.shib_authncontext_class.present? }

  scope :active, -> { where('expires > CURRENT_TIMESTAMP') }
  scope :expired, -> { where('expires <= CURRENT_TIMESTAMP') }

  validate do
    Time.zone.parse(expires.to_s)
  rescue StandardError
    errors[:expires] << "must be a valid timestamp, not #{expires}"
  end

  HUMANIZED_ATTRIBUTES = {
    iprestrict: 'IP Restriction'
  }.freeze

  def self.human_attribute_name(attr, options = {})
    HUMANIZED_ATTRIBUTES[attr.to_sym] || super
  end

  # Grab an expiration_date object. And yes, the long method name is deserved.
  # rubocop:disable
  def construct_and_set_expiration_date
    @expiration_date = ExpirationDate.new(self[:expires], self[:expire_type])
  end
  # rubocop:enable

  # Update expiration_date only if it already exists, because factorybot updates
  # stuff in order and we might not have the expire_type yet
  # This seems like a dumb way to deal with the testing framework, but I'm
  # not sure what else to do. Maybe just reorder the factory definition
  # and put a note in there?
  def expires=(val)
    self[:expires] = val
    @expiration_date = expiration_date(:force_update) unless @expiration_date.nil?
    expires
  end

  def expiration_date(force_update = false)
    if force_update || @expiration_date.nil?
      type                = expire_type
      date                = expires
      @expiration_date = ExpirationDate.new(date, type.to_s)
    end
    @expiration_date
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

  ## Forward some stuff to @expiration_date

  # Display datetime without UTC suffix or just date
  def expires_string
    expiration_date.to_s
  end

  # How many days until expiration?
  # @return [Number] days until expiration
  def days_until_expiration
    expiration_date.days_until_expiration
  end

  # Is this person expiring "soon" (based on the config)?
  # @return [Boolean]
  def expiring_soon?
    expiration_date.expiring_soon?
  end

  def expired?
    expiration_date.expired?
  end

  def extend_by_default_period!
    self.expires = expiration_date.default_extension_date.to_date
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
