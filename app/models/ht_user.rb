# frozen_string_literal: true

class HTUser < ApplicationRecord
  validates :iprestrict, presence: true,
                         format: { with: /\A(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\z/,
                                   message: 'requires a valid IPv4 address' }

  HUMANIZED_ATTRIBUTES = {
    iprestrict: 'IP Restriction'
  }.freeze

  def self.human_attribute_name(attr, options = {})
    HUMANIZED_ATTRIBUTES[attr.to_sym] || super
  end

  def to_param
    Base64.encode64(userid)
  end

  # iprestrict is in the database as an escaped IPv4 regex e.g., ^127\.0\.0\.1$
  # For the UI we strip out and restore the ^/./$ characters
  def iprestrict
    escaped = self[:iprestrict]
    return escaped if escaped.nil?

    escaped.gsub(/^\^/, '').gsub(/\$$/, '').gsub(/\\\./, '.')
  end

  def iprestrict=(val)
    escaped = '^' + val.gsub('.', '\.') + '$'
    write_attribute(:iprestrict, escaped)
  end
end
