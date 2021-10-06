# frozen_string_literal: true

class HTRegistration < ApplicationRecord
  self.primary_key = "id"

  # belongs_to :ht_institution, foreign_key: "inst_id", primary_key: :entityID, required: true
  validates :inst_id, presence: true

  validates :jira_ticket, presence: true
  validates :name, presence: true
  validates :contact_info, presence: true

  # auth_rep = authorized representative
  validates :auth_rep_name, presence: true
  validates :auth_rep_email, presence: true, format: {with: URI::MailTo::EMAIL_REGEXP}
  validates :auth_rep_date, presence: true

  # dsp = disability service provider
  validates :dsp_name, presence: true
  validates :dsp_email, presence: true, format: {with: URI::MailTo::EMAIL_REGEXP}
  validates :dsp_date, presence: true

  # mfa = multi factor authentication
  validates :mfa_addendum, presence: true
end
