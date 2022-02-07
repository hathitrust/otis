# frozen_string_literal: true

class RegistrationMailerPreview < ActionMailer::Preview
  def registration_email
    reg = HTRegistration.all.sample(1).first
    reg.sent = Time.zone.now
    controller = ActionController::Base.new
    # Hard-coded here because URL generation in ActionMailer is annoying,
    # and URL generation in ActionMailer::Preview is rage-inducing.
    finalize_url = "http://localhost:3000/useradmin/finalize/#{reg.token}"
    body = controller.render_to_string partial: "shared/registration_body",
      locals: {"@registration": reg, "@finalize_url": finalize_url}
    RegistrationMailer.with(registration: reg, body: body).registration_email
  end
end
