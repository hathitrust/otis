# frozen_string_literal: true

class OtisLogsController < ApplicationController
  def index
    logs = OtisLog.order(:time)
    @logs = logs.map { |log| OtisLogPresenter.new(log) }

    respond_to do |format|
      format.html
      format.json do
        send_data logs.to_json, type: :json, disposition: "inline"
      end
    end
  end
end
