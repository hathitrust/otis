# frozen_string_literal: true

require "test_helper"

class HTRegistrationPresenterTest < ActiveSupport::TestCase
  def setup
    @registration = HTRegistrationPresenter.new(build(:ht_registration))
  end

  test "jira_link" do
    assert_not_nil @registration.jira_link
    assert_match "#{JIRA_BASE_URL}/#{@registration.jira_ticket}", @registration.jira_link
  end

  test "edit_link" do
    assert_not_nil @registration.edit_link
    assert_match /#{@registration.id}.+>#{@registration.name}</, @registration.edit_link
  end

  test "inst_link" do
    assert_not_nil @registration.inst_link
    assert_match /#{@registration.inst_id}.+>#{@registration.inst_id}</, @registration.inst_link
  end

  test "contact" do
    # auth_contact and dsp_contact just call contact, so not adding tests for them
    contact = @registration.contact("xax", "xbx", "xcx")
    assert_match /xax.+mailto:xbx.+>xbx<.+xcx/, contact
  end
end
