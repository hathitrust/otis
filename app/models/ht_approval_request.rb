# frozen_string_literal: true

class HTApprovalRequest < ApplicationRecord
  self.primary_key = "id"
  def self.expiration_date
    Date.today - 1.week
  end
  # "Active" requests that may be subject to further action
  scope :not_renewed, -> { where(renewed: nil) }
  # "Inactive" requests that are only of historical interest
  scope :renewed, -> { where.not(renewed: nil) }
  scope :expired, -> { where(renewed: nil, received: nil).where.not(sent: nil).where("sent < ?", HTApprovalRequest.expiration_date) }
  scope :for_approver, ->(approver) { where(approver: approver).order(:sent, :received, :renewed) }
  scope :for_user, ->(user) { where(userid: user).order(:sent, :received, :renewed) }
  # Make sure that the most recent and most "incomplete" request comes first when fetching request for user
  # If we had created/updated timestamps we could use those.
  most_recent_order = {Arel.sql("sent IS NULL") => :desc, :sent => :desc,
                       Arel.sql("received IS NULL") => :desc, :received => :desc,
                       Arel.sql("renewed IS NULL") => :desc, :renewed => :desc}
  scope :most_recent, ->(user) { for_user(user).order(most_recent_order) }
  scope :not_approved, -> { where(received: nil) }
  scope :approved, -> { where.not(received: nil) }
  validates :approver, presence: true
  validates :ht_user, uniqueness: {
    conditions: -> { not_renewed },
    message: ->(_object, data) { "#{data[:value]} already has an approval request" }
  }
  validates :token_hash, presence: true, if: :sent
  validates :sent, presence: true, if: :token_hash
  validate :sent_before_received
  belongs_to :ht_user, foreign_key: :userid, primary_key: :email

  def sent_before_received
    return unless self[:sent].present? && self[:received].present? && self[:sent] > self[:received]

    errors.add(:sent, "date sent cannot be after date received")
  end

  def self.digest(tok)
    Digest::SHA256.base64digest(Base64.decode64(tok))
  end

  def self.find_by_token(tok)
    find_by_token_hash(digest(tok))
  end

  # This is the bit that goes to the approver, just a gob of b64 data acting as a 'password'
  def token
    @token ||= SecureRandom.urlsafe_base64 16
  end

  # Display datetime without UTC suffix or just date
  def sent(short: false)
    short ? self[:sent]&.strftime("%Y-%m-%d") : self[:sent]&.to_s(:db)
  end

  def sent=(value)
    self[:sent] = value
    self[:token_hash] = self.class.digest(token)
  end

  def received(short: false)
    date_field(:received, short: short)
  end

  def renewed(short: false)
    date_field(:renewed, short: short)
  end

  # Approval requests are good for a week once the e-mail is sent.
  def expired?
    self[:sent].present? && self[:sent] < HTApprovalRequest.expiration_date
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
      self[field]&.strftime("%Y-%m-%d")
    else
      self[field]&.to_s(:db)
    end
  end
end
