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
    build(:ht_download) do |dl|
      create(:ht_user) do |user|
        dl.email = user.email
        dl.inst_code = user.ht_institution.inst_id
        assert dl.institution_name
      end
    end
  end

  test "#hf" do
    build(:ht_download) do |dl|
      assert dl.hf
    end
  end

  test "#role" do
    build(:ht_download) do |dl|
      assert dl.role
    end
  end

  test "#partial?" do
    build(:ht_download, is_partial: 1) do |dl|
      assert_equal(dl.partial?, true)
    end
  end

  test "#pages" do
    build(:ht_download, is_partial: 1) do |dl|
      assert_operator(dl.pages, :>=, 1)
    end
  end

  test ".for_role" do
    2.times do
      create(:ht_download, role: "resource_sharing")
      create(:ht_download, role: "ssdproxy")
    end

    assert_equal(HTDownload.for_role("resource_sharing").size, 2)
  end

  # has partial?
  # has pages
end
