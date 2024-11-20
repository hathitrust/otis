# frozen_string_literal: true

require "test_helper"

class HTBillingMemberPresenterTest < ActiveSupport::TestCase
  test "class constants" do
    assert_not_nil HTBillingMemberPresenter::ALL_FIELDS
    assert_equal 5, HTBillingMemberPresenter::ALL_FIELDS.count
  end

  test "#field_value :status enabled" do
    member = HTBillingMemberPresenter.new(create(:ht_billing_member, status: true))
    assert_match "bg-success", member.field_value(:status)
  end

  test "#field_value :status disabled" do
    member = HTBillingMemberPresenter.new(create(:ht_billing_member, status: false))
    assert_match "bg-danger", member.field_value(:status)
  end

  test "#field_value :status edits as checkbox" do
    member = HTBillingMemberPresenter.new(create(:ht_billing_member))
    assert_equal "CHECK BOX", member.field_value(:status, form: FakeForm.new)
  end
end
