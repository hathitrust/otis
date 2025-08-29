# frozen_string_literal: true

require "test_helper"

module Otis
  class JiraClientTest < ActiveSupport::TestCase
    test "creates an object" do
      assert_not_nil Otis::JiraClient.new
    end

    test "#find with nonexistent ticket raises StandardError" do
      assert_raises StandardError do
        Otis::JiraClient.new.find(Otis::JiraClient::BOGUS_TICKET)
      end
    end
  end
end
