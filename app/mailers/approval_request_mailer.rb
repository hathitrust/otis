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

    attachments.inline["HathiTrust_logo.png"] = File.read("#{Rails.root}/app/assets/images/HathiTrust_logo.png")
    mail(to: approvers.first, subject: @subject)
  end
end
