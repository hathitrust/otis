# frozen_string_literal: true

class HTApprovalRequestPresenter
  def initialize(req)
    @req = req
  end

  def badge
    @badges ||= {
      unsent: '<span class="label label-warning">Unsent</span>',
      sent: '<span class="label label-default">Sent</span>',
      expired: '<span class="label label-danger">Expired</span>',
      approved: '<span class="label label-info">Approved</span>',
      renewed: '<span class="label label-success">Renewed</span>'
    }
    return '' if @req.nil?

    @badges[@req.renewal_state]&.html_safe
  end
end
