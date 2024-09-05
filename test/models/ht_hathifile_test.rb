# frozen_string_literal: true

require "test_helper"

class HTHathifileTest < ActiveSupport::TestCase
  test ".ransackable_attributes" do
    assert_kind_of Array, HTHathifile.ransackable_attributes
  end

  test ".ransackable_associations" do
    assert_kind_of Array, HTHathifile.ransackable_associations
  end
end
