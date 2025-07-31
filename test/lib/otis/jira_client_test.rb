# frozen_string_literal: true

require "test_helper"

module Otis
  class JiraClientTest < ActiveSupport::TestCase
    test "creates an object" do
      assert_not_nil Otis::JiraClient.new
    end

    test "#find with nonexistent ticket returns nil instead of raising" do
      assert_nil Otis::JiraClient.new.find("does not exist")
    end
  end
end
