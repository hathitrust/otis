# frozen_string_literal: true

require "test_helper"

module Otis
  class JiraClientTest < ActiveSupport::TestCase
    test "comment template substitutes __USER__ placeholder" do
      comment = Otis::JiraClient.comment template: :registration_sent, user: "nobody@default.invalid"
      assert_match "nobody@default.invalid", comment
    end

    test "creates an object" do
      assert_not_nil Otis::JiraClient.new
    end

    test "#update_ea_ticket! creates ticket if missing" do
      @inst = create(:ht_institution)
      @registration = create(:ht_registration, inst_id: @inst.inst_id, jira_ticket: nil)
      Otis::JiraClient.new.update_ea_ticket!(@registration)
      # Registration will have new EA ticket
      assert_equal("EA-0", @registration.jira_ticket)
    end

    test "#update_ea_ticket! creates ticket if GS ticket is entered" do
      @inst = create(:ht_institution)
      @registration = create(:ht_registration, inst_id: @inst.inst_id, jira_ticket: "GS-0")
      Otis::JiraClient.new.update_ea_ticket!(@registration)
      # Registration will have new EA ticket
      assert_equal("EA-0", @registration.jira_ticket)
    end

    test "#update_ea_ticket! does not create ticket if it already has one" do
      @inst = create(:ht_institution)
      @registration = create(:ht_registration, inst_id: @inst.inst_id, jira_ticket: "EA-99")
      Otis::JiraClient.new.update_ea_ticket!(@registration)
      # Registration will have existing ticket
      assert_equal("EA-99", @registration.jira_ticket)
    end

    test "#find with nonexistent ticket returns nil instead of raising" do
      assert_nil Otis::JiraClient.new.find("does not exist")
    end
  end
end
