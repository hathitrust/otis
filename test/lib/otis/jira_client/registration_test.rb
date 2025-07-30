# frozen_string_literal: true

require "test_helper"

module Otis
  class JiraClient::RegistrationTest < ActiveSupport::TestCase
    test "comment template substitutes __USER__ placeholder" do
      comment = Otis::JiraClient::Registration.comment template: :registration_sent, user: "nobody@default.invalid"
      assert_match "nobody@default.invalid", comment
    end

    test "#update_ea_ticket! creates ticket if missing" do
      @inst = create(:ht_institution)
      @registration = create(:ht_registration, inst_id: @inst.inst_id, jira_ticket: nil)
      Otis::JiraClient::Registration.new(@registration, "https://www.example.com").update_ea_ticket!
      # Registration will have new EA ticket
      assert_equal("EA-0", @registration.jira_ticket)
    end

    test "#update_ea_ticket! creates ticket if GS ticket is entered" do
      @inst = create(:ht_institution)
      @registration = create(:ht_registration, inst_id: @inst.inst_id, jira_ticket: "GS-0")
      Otis::JiraClient::Registration.new(@registration, "https://www.example.com").update_ea_ticket!
      # Registration will have new EA ticket
      assert_equal("EA-0", @registration.jira_ticket)
    end

    test "#update_ea_ticket! does not create ticket if it already has one" do
      @inst = create(:ht_institution)
      @registration = create(:ht_registration, inst_id: @inst.inst_id, jira_ticket: "EA-99")
      Otis::JiraClient::Registration.new(@registration, "https://www.example.com").update_ea_ticket!
      # Registration will have existing ticket
      assert_equal("EA-99", @registration.jira_ticket)
    end
  end
end
