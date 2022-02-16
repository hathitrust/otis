# frozen_string_literal: true

require "expiration_date"
require "forwardable"

class HTUserRenewalError < StandardError
  attr_reader :type
  TYPES = %i[missing].freeze

  def initialize(msg = "Renewal Error", type:)
    @type = type
    super msg
  end
end

class HTUser < ApplicationRecord
  ROLES = %i[corrections cataloging ssdproxy crms quality staffdeveloper staffsysadmin replacement ssd].freeze
  USERTYPES = %i[staff external student].freeze
  ACCESSES = %i[total normal].freeze
  self.primary_key = "email"

  belongs_to :ht_institution, foreign_key: :inst_id, primary_key: :inst_id
  has_one :ht_count, foreign_key: :userid, primary_key: :userid
  has_many :ht_logs, -> { HTLog.ht_user }, foreign_key: :objid, primary_key: :email
  has_many :ht_approval_request, foreign_key: :userid, primary_key: :email

  validates :iprestrict, presence: true, unless: :mfa
  validate :validate_iprestrict
  validate :validate_expires

  validates :email, presence: true, uniqueness: true
  validates :userid, presence: true
  validates :expires, presence: true
  validates :inst_id, presence: true
  validates :approver, presence: true

  validates :mfa, absence: true, unless: -> { ht_institution.shib_authncontext_class.present? }

  scope :active, -> { where("expires > CURRENT_TIMESTAMP") }
  scope :expired, -> { where("expires <= CURRENT_TIMESTAMP") }

  after_save :clean_requests

  # Checkpoint override
  def resource_id
    email
  end

  # Work around the fact that Rails' built-in typecasting clobbers various bogus
  # dates into nil. https://stackoverflow.com/a/35553281
  def validate_expires
    if expires.nil? && respond_to?(:expires_before_type_cast)
      raw_data = expires_before_type_cast.to_s
      begin
        Time.zone.parse(raw_data)
      rescue
        errors.add(:expires, :invalid)
      end
    end
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
  # This is used by the approval request mailer which is not yet really locale-aware.
  # Otherwise we would ditch it.
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
    rescue IPRestrictionError => e
      errors.add :iprestrict, e.type, addr: e.address
    end
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

    raise(HTUserRenewalError.new(type: :no_approved_request)) unless req

    req.renewed = Time.zone.now
    req.save!
    renew!
  end

  def csv_cols
    attributes.keys + ["inst_name"]
  end

  def csv_vals
    attributes.values + [institution]
  end

  private

  def clean_requests
    if saved_change_to_approver? || (saved_change_to_expires? &&
                                     expiration_date(true).days_until_expiration < 1)
      ht_approval_request.not_approved.not_renewed.destroy_all
    end
  end
end
