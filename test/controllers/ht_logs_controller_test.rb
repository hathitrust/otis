# frozen_string_literal: true

require "test_helper"

class HTLogsControllerTest < ActionDispatch::IntegrationTest
  def setup
    4.times { create(:ht_log) }
  end

  test "should get index" do
    sign_in!
    get ht_logs_url
    assert_response :success
    assert_not_nil assigns(:logs)
    assert_equal "index", @controller.action_name
    assert_match "Logs", @response.body
  end
end

class HTLogsControllerJSONTest < ActionDispatch::IntegrationTest
  def setup
    4.times { create(:ht_log) }
  end

  test "export list of all logs as JSON" do
    sign_in!
    get ht_logs_url format: :json
    HTLog.all.each do |log|
      assert_match log.objid, @response.body
    end
    assert_kind_of Array, JSON.parse(@response.body)
  end
end
