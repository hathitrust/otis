# frozen_string_literal: true

require "expiration_date"
require "forwardable"

class HTUser < ApplicationRecord
  self.primary_key = "email"

  belongs_to :ht_institution, foreign_key: :identity_provider, primary_key: :entityID
  has_one :ht_count, foreign_key: :userid, primary_key: :userid
  has_many :ht_logs, -> { HTLog.ht_user }, foreign_key: :objid, primary_key: :email
  has_many :ht_approval_request, foreign_key: :userid, primary_key: :email

  validates :iprestrict, presence: true, unless: :mfa
  validate :validate_iprestrict

  validates :email, presence: true
  validates :userid, presence: true
  validates :expires, presence: true
  validates :identity_provider, presence: true
  validates :approver, presence: true

  validates :mfa, absence: true, unless: -> { ht_institution.shib_authncontext_class.present? }

  scope :active, -> { where("expires > CURRENT_TIMESTAMP") }
  scope :expired, -> { where("expires <= CURRENT_TIMESTAMP") }

  after_save :clean_requests

  validate do
    Time.zone.parse(expires.to_s)
  rescue
    errors[:expires] << "must be a valid timestamp, not #{expires}"
  end

  HUMANIZED_ATTRIBUTES = {
    iprestrict: "IP Restriction"
  }.freeze

  def self.human_attribute_name(attr, options = {})
    HUMANIZED_ATTRIBUTES[attr.to_sym] || super
  end

  # Checkpoint override
  def resource_id
    email
  end

  # Grab an expiration_date object. And yes, the long method name is deserved.
  def construct_and_set_expiration_date
    @expiration_date = ExpirationDate.new(self[:expires], self[:expire_type])
  end

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
      type = expire_type
      date = expires
      @expiration_date = ExpirationDate.new(date, type.to_s)
    end
    @expiration_date
  end

  # iprestrict is in the database as an escaped IPv4 regex e.g., ^127\.0\.0\.1$
  # For the UI we strip out and restore the ^/./$ characters
  # Since multiple addresses are permitted if separated by OR (|) this value is
  # an array.
  def iprestrict
    return nil unless self[:iprestrict]

    IPRestriction.from_regex(self[:iprestrict]).addrs
  end

  def iprestrict=(vals)
    self[:iprestrict] = if vals
      IPRestriction.from_string(vals).to_regex
    end
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
  def validate_iprestrict
    return unless self[:iprestrict].present?

    begin
      IPRestriction.from_regex(self[:iprestrict]).validate
    rescue ArgumentError => e
      errors.add :iprestrict, e.message
    end
  end

  def approval_requested?
    ht_approval_request.count.positive?
  end

  def renew!
    extend_by_default_period!
    save!
  end

  def add_or_update_renewal(approver:, force: false)
    req = ht_approval_request.approved.not_renewed.first

    if force
      req ||= ht_approval_request.not_renewed.first
      req ||= HTApprovalRequest.new(approver: approver, ht_user: self)
    end

    raise("No approved request for #{email}; must be renewed manually") unless req

    req.renewed = Time.zone.now
    req.save!
    renew!
  end

  def csv_cols
    extra_cols = ["inst_id", "inst_name"]
    attributes.keys + extra_cols
  end

  def csv_vals
    extra_vals = [ht_institution.inst_id, institution]
    attributes.values + extra_vals
  end

  private

  def clean_requests
    if saved_change_to_approver? || (saved_change_to_expires? &&
                                     expiration_date(true).days_until_expiration < 1)
      ht_approval_request.not_approved.not_renewed.destroy_all
    end
  end
end
