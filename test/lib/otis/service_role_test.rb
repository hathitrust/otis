# frozen_string_literal: true

require "test_helper"

module Otis
  class ServiceRoleTest < ActiveSupport::TestCase
    test "get service role name for each role recognized by `HTRegistration`" do
      HTRegistration::ROLES.each do |role|
        assert_not_nil ServiceRole.new(role).name
      end
    end

    test "get service role full name for each role recognized by `HTRegistration`" do
      HTRegistration::ROLES.each do |role|
        assert_not_nil ServiceRole.new(role).name
      end
    end
  end
end
