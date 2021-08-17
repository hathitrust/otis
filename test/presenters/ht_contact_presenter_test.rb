# frozen_string_literal: true

require "test_helper"

class HTContactPresenterTest < ActiveSupport::TestCase
  def setup
    @type = create(:ht_contact_type)
    @inst = create(:ht_institution)
    @contact = HTContactPresenter.new(create(:ht_contact, ht_institution: @inst, ht_contact_type: @type))
  end

  test "#inst_link" do
    assert_not_nil @contact.inst_link
    assert_match "/ht_contacts/#{@contact.id}", @contact.inst_link
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
    assert_match "/ht_contacts/#{@contact.id}", @contact.cancel_button
  end

  test "#cancel_button for unsaved object goes to index" do
    contact = HTContactPresenter.new(build(:ht_contact))
    assert_not_nil contact.cancel_button
    assert_no_match "/ht_contacts/#{contact.id}", contact.cancel_button
  end
end
