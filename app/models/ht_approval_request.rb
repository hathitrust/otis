# frozen_string_literal: true

class HTApprovalRequest < ApplicationRecord
  self.primary_key = 'id'
  scope :not_renewed, -> { where(renewed: nil) }
  scope :for_approver, ->(approver) { where(approver: approver).order(:sent, :received, :renewed) }
  scope :not_renewed_for_approver, ->(approver) { where(approver: approver, renewed: nil).order(:sent, :received, :renewed) }
  scope :for_user, ->(user) { where(userid: user) }
  scope :not_renewed_for_user, ->(user) { where(userid: user, renewed: nil) }
  validates :approver, presence: true
  validates :userid, presence: true
  validates :userid, uniqueness: {
    constraint: -> { not_renewed },
    message: ->(_object, data) { "#{data[:value]} already has an approval request" }
  }
  validates :crypt, presence: true, if: :sent
  validates :sent, presence: true, if: :crypt
  validate :sent_before_received

  def sent_before_received
    return unless self[:sent].present? && self[:received].present? && self[:sent] > self[:received]

    errors.add(:sent, 'date sent cannot be after date received')
  end

  def self.find_by_token(tok)
    HTApprovalRequest.find { |req| req if req.equals_token?(tok) }
  end

  # This is the bit that goes to the approver, just a gob of b64 data acting as a 'password'
  def token
    @token ||= decrypt(self[:crypt]) if self[:crypt]
    @token ||= SecureRandom.urlsafe_base64 16
  end

  # Does the approver alleging to have a valid token match this one?
  def equals_token?(token)
    decrypt(self[:crypt]) == token.to_s
  end

  # Display datetime without UTC suffix or just date
  def sent(short: false)
    short ? self[:sent]&.strftime('%Y-%m-%d') : self[:sent]&.to_s(:db)
  end

  def sent=(value)
    self[:sent] = value
    self[:crypt] = encrypt(token) unless self[:crypt].present?
  end

  def received(short: false)
    date_field(:received, short: short)
  end

  def renewed(short: false)
    date_field(:renewed, short: short)
  end

  def ht_user
    HTUser.find(userid)
  end

  # Approval requests are good for a week once the e-mail is sent.
  def expired?
    self[:sent].present? && self[:sent] < (Date.today - 1.week)
  end

  # Expired or unsent
  def mailable?
    %i[unsent expired].include? renewal_state
  end

  def renewal_state
    return :renewed if self[:renewed].present?

    return :approved if self[:received].present?

    return :expired if expired?

    return :sent if self[:sent].present?

    :unsent
  end

  private

  # https://dev.to/shobhitic/simple-string-encryption-in-rails-36pi
  def encrypt(text)
    text = text.to_s unless text.is_a? String
    len = ActiveSupport::MessageEncryptor.key_len
    salt = SecureRandom.hex len
    key = ActiveSupport::KeyGenerator.new(Rails.application.secret_key_base).generate_key salt, len
    crypt = ActiveSupport::MessageEncryptor.new key
    encrypted_data = crypt.encrypt_and_sign text
    "#{salt}$$#{encrypted_data}"
  end

  def decrypt(text)
    return unless text

    salt, data = text.split '$$'
    len = ActiveSupport::MessageEncryptor.key_len
    key = ActiveSupport::KeyGenerator.new(Rails.application.secret_key_base).generate_key salt, len
    crypt = ActiveSupport::MessageEncryptor.new key
    crypt.decrypt_and_verify data
  end

  def date_field(field, short: false)
    if short
      self[field]&.strftime('%Y-%m-%d')
    else
      self[field]&.to_s(:db)
    end
  end
end
