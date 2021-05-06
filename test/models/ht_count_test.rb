# frozen_string_literal: true

require "test_helper"

class HTCountTest < ActiveSupport::TestCase
  def setup
    @user1 = create(:ht_user)
  end

  test "validation fails if user does not exist" do
    assert_not build(:ht_count).valid?
  end

  test "validation passes" do
    assert build(:ht_count, userid: @user1.userid).valid?
  end
end
