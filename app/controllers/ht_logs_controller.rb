# frozen_string_literal: true

class HTLogsController < ApplicationController
  def index
    logs = HTLog.order(:time)
    @logs = logs.map { |log| presenter log }

    respond_to do |format|
      format.html
      format.json do
        send_data logs.to_json, type: :json, disposition: "inline"
      end
    end
  end

  private

  def presenter(log)
    HTLogPresenter.new(log, controller: self, action: params[:action].to_sym)
  end
end
