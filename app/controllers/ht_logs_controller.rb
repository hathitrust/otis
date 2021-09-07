# frozen_string_literal: true

class HTLogsController < ApplicationController
  def index
    logs = HTLog.order(:time)
    @logs = logs.map { |log| HTLogPresenter.new(log) }

    respond_to do |format|
      format.html
      format.json do
        send_data logs.to_json, type: :json, disposition: "inline"
      end
    end
  end
end
