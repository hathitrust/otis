# frozen_string_literal: true

require "test_helper"

class ContactPresenterTest < ActiveSupport::TestCase
  def setup
    @type = create(:contact_type)
    @inst = create(:ht_institution)
    @contact = ContactPresenter.new(create(:contact, ht_institution: @inst, contact_type: @type))
  end

  test "#inst_link" do
    assert_not_nil @contact.inst_link
    assert_match "/contacts/#{@contact.id}", @contact.inst_link
  end

  test "#institution_display" do
    assert_not_nil @contact.institution_display
    assert_match @inst.name, @contact.institution_display
  end

  test "#contact_type_display" do
    assert_not_nil @contact.contact_type_display
    assert_match @type.name, @contact.contact_type_display
  end

  test "#email_display" do
    assert_not_nil @contact.email_display
    assert_match "mailto", @contact.email_display
  end

  test "#cancel_button for saved object goes to object" do
    assert_not_nil @contact.cancel_button
    assert_match "/contacts/#{@contact.id}", @contact.cancel_button
  end

  test "#cancel_button for unsaved object goes to index" do
    contact = ContactPresenter.new(build(:contact))
    assert_not_nil contact.cancel_button
    assert_no_match "/contacts/#{contact.id}", contact.cancel_button
  end
end
