# frozen_string_literal: true

require "test_helper"

class ContactTypeTest < ActiveSupport::TestCase
  test "validation fails without name and description" do
    assert_not ContactType.new.valid?
  end

  test "validation passes" do
    assert build(:contact_type, name: "Something", description: "Something").valid?
  end

  test "name must be unique" do
    existing_type = create(:contact_type)
    assert_not build(:contact_type, name: existing_type.name, description: "Something").valid?
  end

  test "name must be not be blank" do
    assert_not build(:contact_type, name: "", description: "Something").valid?
  end

  test "description must not be blank" do
    assert_not build(:contact_type, name: "Something", description: "").valid?
  end

  test "correct Checkpoint resource_type and resource_id" do
    type = build(:contact_type, name: "Something", description: "Something")
    assert_equal :contact_type, type.resource_type
    assert_equal type.id, type.resource_id
  end
end
