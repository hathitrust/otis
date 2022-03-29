# frozen_string_literal: true

require "test_helper"
require "otis/jira_client"

module Otis
  class JiraClientTest < ActiveSupport::TestCase
    test "comment template substitutes __USER__ placeholder" do
      comment = Otis::JiraClient.comment template: :registration_sent, user: "nobody@default.invalid"
      assert_match "nobody@default.invalid", comment
    end

    test "creates an object" do
      assert_not_nil Otis::JiraClient.new
    end
  end
end
