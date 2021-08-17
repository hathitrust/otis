# frozen_string_literal: true

require "test_helper"

class HTContactTest < ActiveSupport::TestCase
  def setup
    @type = create(:ht_contact_type)
    @inst = create(:ht_institution)
    @contact = create(:ht_contact, contact_type: @type.id, inst_id: @inst.inst_id)
  end

  test "validation fails without institution" do
    assert_not build(:ht_contact, inst_id: nil).valid?
  end

  test "validation fails without type" do
    assert_not build(:ht_contact, contact_type: nil).valid?
  end

  test "validation fails without email" do
    assert_not build(:ht_contact, email: nil).valid?
  end

  test "validation passes" do
    assert build(:ht_contact, email: "me@here.org").valid?
  end

  test "validation fails with invalid email" do
    assert_not build(:ht_contact, inst_id: @inst.inst_id, contact_type: @type.id,
                                  email: "me#here.org").valid?
  end

  test "correct Checkpoint resource_type and resource_id" do
    assert_equal :ht_contact, @contact.resource_type
    assert_equal @contact.id, @contact.resource_id
  end
end
