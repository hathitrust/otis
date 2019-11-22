# frozen_string_literal: true

class HTUser < ApplicationRecord
  self.primary_key = 'email'
  belongs_to :ht_institution, foreign_key: :identity_provider, primary_key: :entityID

  validates :iprestrict, presence: true,
                         format: { with: /\A(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\z/,
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
    val = val.strip
    escaped = '^' + val.gsub('.', '\.') + '$'
    write_attribute(:iprestrict, escaped)
  end

  # Display datetime without UTC suffix or just date
  def expires(short: false)
    short ? self[:expires]&.strftime('%Y-%m-%d') : self[:expires]&.to_s(:db)
  end

  def institution
    ht_institution&.name
  end
end
