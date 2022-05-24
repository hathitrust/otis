# frozen_string_literal: true

require "test_helper"

module Otis
  class DailyDigestTaskTest < ActiveSupport::TestCase
    def setup
      Application.load_tasks
    end

    test "task runs without errors" do
      Rake::Task["otis:send_daily_digest"].invoke
    end
  end
end
