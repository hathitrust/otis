# frozen_string_literal: true

require "test_helper"

module Otis
  class JiraClient::RegistrationTest < ActiveSupport::TestCase
    EXAMPLE_URL = "https://www.example.com"

    test "#update_ea_ticket! creates ticket if missing" do
      @inst = create(:ht_institution)
      @registration = create(:ht_registration, inst_id: @inst.inst_id, jira_ticket: nil)
      Otis::JiraClient::Registration.new(@registration, EXAMPLE_URL).update_ea_ticket!
      # Registration will have new EA ticket
      assert_equal("EA-0", @registration.jira_ticket)
    end

    test "#update_ea_ticket! creates ticket if GS ticket is entered" do
      @inst = create(:ht_institution)
      @registration = create(:ht_registration, inst_id: @inst.inst_id, jira_ticket: "GS-0")
      Otis::JiraClient::Registration.new(@registration, EXAMPLE_URL).update_ea_ticket!
      # Registration will have new EA ticket
      assert_equal("EA-0", @registration.jira_ticket)
    end

    test "#update_ea_ticket! does not create ticket if it already has one" do
      @inst = create(:ht_institution)
      @registration = create(:ht_registration, inst_id: @inst.inst_id, jira_ticket: "EA-99")
      Otis::JiraClient::Registration.new(@registration, EXAMPLE_URL).update_ea_ticket!
      # Registration will have existing ticket
      assert_equal("EA-99", @registration.jira_ticket)
    end

    test "#ea_fields always returns a Hash" do
      @inst = create(:ht_institution)
      @registration = create(:ht_registration, inst_id: @inst.inst_id, jira_ticket: "EA-99")
      fields = Otis::JiraClient::Registration.new(@registration, EXAMPLE_URL).ea_fields
      assert_kind_of(Hash, fields)
    end

    test "#ea_fields returns a Hash" do
      @inst = create(:ht_institution)
      @registration = create(:ht_registration, inst_id: @inst.inst_id, jira_ticket: "EA-99")
      fields = Otis::JiraClient::Registration.new(@registration, EXAMPLE_URL).ea_fields
      assert_kind_of(Hash, fields)
      assert_not_nil(fields[:fields])
    end

    test "#ea_fields returns a Hash with the GS ticket custom field if supplied" do
      @inst = create(:ht_institution)
      @registration = create(:ht_registration, inst_id: @inst.inst_id, jira_ticket: "GS-99")
      fields = Otis::JiraClient::Registration.new(@registration, EXAMPLE_URL).ea_fields
      assert_kind_of(Hash, fields)
      assert_equal("GS-99", fields[:fields][JiraClient::Registration::EA_REGISTRATION_GS_TICKET_FIELD])
    end

    test "#service_name" do
      @registration = create(:ht_registration, role: "resource_sharing")
      @jc = Otis::JiraClient::Registration.new(@registration, EXAMPLE_URL)
      assert_equal("RS", @jc.service_name)
    end

    test "#full_service_name" do
      @registration = create(:ht_registration, role: "resource_sharing")
      @jc = Otis::JiraClient::Registration.new(@registration, EXAMPLE_URL)
      assert_equal("Resource Sharing", @jc.full_service_name)
    end

    test "#finalize!" do
      @registration = create(:ht_registration, role: "resource_sharing")
      assert_nothing_raised do
        @jc = Otis::JiraClient::Registration.new(@registration, EXAMPLE_URL).finalize!
      end
    end

    test "#finish!" do
      @registration = create(:ht_registration, role: "resource_sharing")
      assert_nothing_raised do
        @jc = Otis::JiraClient::Registration.new(@registration, EXAMPLE_URL).finish!
      end
    end
  end
end
