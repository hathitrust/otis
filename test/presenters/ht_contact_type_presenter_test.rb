# frozen_string_literal: true

require "test_helper"

class HTContactTypePresenterTest < ActiveSupport::TestCase
  test "class constants" do
    assert_not_nil HTContactTypePresenter::ALL_FIELDS
    assert_equal 3, HTContactTypePresenter::ALL_FIELDS.count
    assert_not_nil HTContactTypePresenter::READ_ONLY_FIELDS
    assert_equal 1, HTContactTypePresenter::READ_ONLY_FIELDS.count
  end

  test "#field_value :name on index page" do
    type = HTContactTypePresenter.new(create(:ht_contact_type), action: :index)
    assert_match "/ht_contact_types/#{type.id}", type.field_value(:name)
  end

  test "#field_value :name elsewhere" do
    %i[edit new show].each do |action|
      type = HTContactTypePresenter.new(create(:ht_contact_type), action: action)
      assert_no_match "ht_contact_types", type.field_value(:name)
    end
  end

  test "#field_value :description edits as text area" do
    type = HTContactTypePresenter.new(create(:ht_contact_type))
    assert_equal "TEXT AREA", type.field_value(:description, form: FakeForm.new)
  end

  test "#cancel_path for persisted object goes to object" do
    type = HTContactTypePresenter.new(create(:ht_contact_type))
    assert_not_nil type.cancel_path
    assert_match "/ht_contact_types/#{type.id}", type.cancel_path
  end

  test "#cancel_path for new object goes to index" do
    type = HTContactTypePresenter.new(build(:ht_contact_type))
    assert_not_nil type.cancel_path
    assert_no_match "/ht_contact_types/#{type.id}", type.cancel_path
  end
end
