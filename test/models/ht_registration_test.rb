# frozen_string_literal: true

require "test_helper"

class HTRegistrationTest < ActiveSupport::TestCase
  test "fail if any req is nil" do
    assert_not build(:ht_registration, inst_id: nil).valid?
    assert_not build(:ht_registration, jira_ticket: nil).valid?
    assert_not build(:ht_registration, name: nil).valid?
    assert_not build(:ht_registration, contact_info: nil).valid?
    assert_not build(:ht_registration, auth_rep_name: nil).valid?
    assert_not build(:ht_registration, auth_rep_email: nil).valid?
    assert_not build(:ht_registration, auth_rep_date: nil).valid?
    assert_not build(:ht_registration, dsp_name: nil).valid?
    assert_not build(:ht_registration, dsp_email: nil).valid?
    assert_not build(:ht_registration, dsp_date: nil).valid?
    assert_not build(:ht_registration, mfa_addendum: nil).valid?
  end

  test "validates email fields" do
    good_email = Faker::Internet.email
    bad_email  = "bad@bad@bad.bad.bad"
    assert build(:ht_registration, auth_rep_email: good_email).valid?
    assert build(:ht_registration, dsp_email: good_email).valid?
    assert_not build(:ht_registration, auth_rep_email: bad_email).valid?
    assert_not build(:ht_registration, dsp_email: bad_email).valid?
    assert_not build(:ht_registration, auth_rep_email: "").valid?
    assert_not build(:ht_registration, dsp_email: "").valid?
    # Already tested nils in "fail if any req is nil"
  end

  test "validation passes if given all the necessary things" do
    assert build(:ht_registration).valid?
  end

  test "objects are persisted" do
    reg = create(:ht_registration)
    persisted = HTRegistration.first
    
    field_symbols = [
      :inst_id,
      :jira_ticket,
      :name,
      :contact_info,
      :auth_rep_name,
      :auth_rep_email,
      :auth_rep_date,
      :dsp_name,
      :dsp_email,
      :dsp_date,
      :mfa_addendum
    ]
    
    field_symbols.each do |field|
      assert_equal reg.public_send(field), persisted.public_send(field)
    end
  end
  
  test "checkpoint: resource_type and resource_id" do
    @registration = create(:ht_registration)
    @inst = create(:ht_institution)
    assert_equal :ht_registration, @registration.resource_type
    assert_equal @registration.id, @registration.resource_id
  end

  test "id must be uniq" do
    reg = create(:ht_registration)
    assert_not build(:ht_registration, id: reg.id).valid?
  end
end
