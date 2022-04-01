# frozen_string_literal: true

class RegistrationMailerPreview < ActionMailer::Preview
  def registration_email
    reg = HTRegistration.all.sample(1).first
    reg.sent = Time.zone.now
    controller = ActionController::Base.new
    base_url = "http://default.invalid"
    body = controller.render_to_string partial: "shared/registration_body",
      locals: {"@registration": reg}
    RegistrationMailer.with(registration: reg, body: body, base_url: base_url)
      .registration_email
  end
end
