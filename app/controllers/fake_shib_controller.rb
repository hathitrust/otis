# frozen_string_literal: true

class FakeShibController < ApplicationController
  skip_before_action :validate_session, :authenticate!, :authorize!

  def new
    raise StandardError, "fake_shib_controller should not be used in Production" if Rails.env.production?

    render "shared/login_form"
  end
end
