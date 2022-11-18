# frozen_string_literal: true

require "test_helper"

class HTContactPresenterTest < ActiveSupport::TestCase
  def setup
    @type = create(:ht_contact_type)
    @inst = create(:ht_institution)
    @contact = HTContactPresenter.new(create(:ht_contact, ht_institution: @inst, ht_contact_type: @type))
  end

  test "class constants" do
    assert_not_nil HTContactPresenter::ALL_FIELDS
    assert_equal 4, HTContactPresenter::ALL_FIELDS.count
    assert_not_nil HTContactPresenter::READ_ONLY_FIELDS
    assert_equal 1, HTContactPresenter::READ_ONLY_FIELDS.count
  end

  test "#field_value :email on index page" do
    contact = HTContactPresenter.new(create(:ht_contact, ht_institution: @inst, ht_contact_type: @type),
      action: :index)
    assert_match "/ht_contacts/#{contact.id}", contact.field_value(:email)
  end

  test "#field_value :email elsewhere" do
    %i[edit new show].each do |action|
      contact = HTContactPresenter.new(create(:ht_contact, ht_institution: @inst, ht_contact_type: @type),
        action: action)
      assert_match "mailto:", contact.field_value(:email)
    end
  end

  test "#field_value :inst_id displays as link" do
    assert_match "ht_institutions/", @contact.field_value(:inst_id)
  end

  # Test a degenerate case seen in production database
  test "#field_value :inst_id displays as blank if institution does not exist" do
    bad_contact = HTContactPresenter.new(create(:ht_contact, ht_contact_type: @type))
    bad_contact.inst_id = "not_a_valid_inst_id"
    assert_equal "", bad_contact.field_value(:inst_id)
  end

  test "#field_value :contact_type displays as link" do
    assert_match "ht_contact_types/", @contact.field_value(:contact_type)
  end

  test "#field_value :inst_id edits as select menu" do
    assert_equal "SELECT", @contact.field_value(:inst_id, form: FakeForm.new)
  end

  test "#field_value :contact_type edits as select menu" do
    assert_equal "SELECT", @contact.field_value(:contact_type, form: FakeForm.new)
  end

  test "#cancel_path for saved object goes to object" do
    assert_match "/ht_contacts/#{@contact.id}", @contact.cancel_path
  end

  test "#cancel_path for unsaved object goes to index" do
    contact = HTContactPresenter.new(build(:ht_contact))
    assert_not_nil contact.cancel_path
    assert_no_match "/ht_contacts/#{contact.id}", contact.cancel_path
  end
end
