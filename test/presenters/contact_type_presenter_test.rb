# frozen_string_literal: true

require "test_helper"

class ContactTypePresenterTest < ActiveSupport::TestCase
  test "#show_link" do
    type = ContactTypePresenter.new(create(:contact_type))
    assert_not_nil type.show_link
    assert_match "/contact_types/#{type.id}", type.show_link
  end

  test "#cancel_button for unsaved object goes to index" do
    type = ContactTypePresenter.new(build(:contact_type))
    assert_not_nil type.cancel_button
    assert_no_match "/contact_types/#{type.id}", type.cancel_button
  end

  test "#cancel_button for saved object goes to object" do
    type = ContactTypePresenter.new(create(:contact_type))
    assert_not_nil type.cancel_button
    assert_match "/contact_types/#{type.id}", type.cancel_button
  end
end
