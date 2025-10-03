# frozen_string_literal: true

require "test_helper"

class HTDownloadTest < ActiveSupport::TestCase
  test "validation passes" do
    assert build(:ht_download).valid?
  end

  test ".ransackable_attributes" do
    assert_kind_of Array, HTDownload.ransackable_attributes
  end

  test ".ransackable_associations" do
    assert_kind_of Array, HTDownload.ransackable_associations
  end

  test "#institution_name" do
    build(:ht_download) do |rep|
      create(:ht_user) do |user|
        rep.email = user.email
        rep.inst_code = user.ht_institution.inst_id
        assert rep.institution_name
      end
    end
  end

  test "#hf" do
    build(:ht_download) do |rep|
      assert rep.hf
    end
  end

  # TODO scope for role
  # has partial?
  # has pages
end
