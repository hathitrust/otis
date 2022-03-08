# frozen_string_literal: true

class ApprovalRequestMailer < ApplicationMailer
  def self.subject
    "HathiTrust Elevated Access Approval Request"
  end

  def approval_request_email
    @reqs = params[:reqs]
    @base_url = params[:base_url]
    @body = params[:body]
    @subject = params[:subject] || ApprovalRequestMailer.subject
    raise StandardError, "Cannot send an email without at least one approval request" unless @reqs.count.positive?

    approvers = @reqs.pluck(:approver).uniq
    raise StandardError, "Approval request e-mail must be for a single approver" unless approvers.count == 1

    mail(to: approvers.first, subject: @subject)
  end
end
