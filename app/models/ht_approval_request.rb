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
  validates :token_hash, presence: true, if: :sent
  validates :sent, presence: true, if: :token_hash
  validate :sent_before_received

  def sent_before_received
    return unless self[:sent].present? && self[:received].present? && self[:sent] > self[:received]

    errors.add(:sent, 'date sent cannot be after date received')
  end

  def self.digest(tok)
    Digest::SHA256.base64digest(Base64.decode64(tok))
  end

  def self.find_by_token(tok)
    HTApprovalRequest.find_by_token_hash(digest(tok))
  end

  # This is the bit that goes to the approver, just a gob of b64 data acting as a 'password'
  def token
    @token ||= SecureRandom.urlsafe_base64 16
  end

  # Display datetime without UTC suffix or just date
  def sent(short: false)
    short ? self[:sent]&.strftime('%Y-%m-%d') : self[:sent]&.to_s(:db)
  end

  def sent=(value)
    self[:sent] = value
    self[:token_hash] = self.class.digest(token) unless self[:token_hash].present?
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

  def date_field(field, short: false)
    if short
      self[field]&.strftime('%Y-%m-%d')
    else
      self[field]&.to_s(:db)
    end
  end
end
