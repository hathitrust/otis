# frozen_string_literal: true

require "test_helper"

class ContactTest < ActiveSupport::TestCase
  def setup
    @type = create(:contact_type)
    @inst = create(:ht_institution)
    @contact = create(:contact, contact_type: @type.id, inst_id: @inst.inst_id)
  end

  test "validation fails without institution" do
    assert_not build(:contact, inst_id: nil).valid?
  end

  test "validation fails without type" do
    assert_not build(:contact, contact_type: nil).valid?
  end

  test "validation fails without email" do
    assert_not build(:contact, email: nil).valid?
  end

  test "validation passes" do
    assert build(:contact, email: "me@here.org").valid?
  end

  test "validation fails with invalid email" do
    assert_not build(:contact, inst_id: @inst.inst_id, contact_type: @type.id,
                                  email: "me#here.org").valid?
  end

  test "correct Checkpoint resource_type and resource_id" do
    assert_equal :contact, @contact.resource_type
    assert_equal @contact.id, @contact.resource_id
  end
end
