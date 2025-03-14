# frozen_string_literal: true

require "test_helper"

class HTSSDProxyReportTest < ActiveSupport::TestCase
  test "validation passes" do
    assert build(:ht_ssd_proxy_report).valid?
  end

  test ".ransackable_attributes" do
    assert_kind_of Array, HTSSDProxyReport.ransackable_attributes
  end

  test ".ransackable_associations" do
    assert_kind_of Array, HTSSDProxyReport.ransackable_associations
  end

  test "#institution_name" do
    build(:ht_ssd_proxy_report) do |rep|
      create(:ht_user) do |user|
        rep.email = user.email
        rep.inst_code = user.ht_institution.inst_id
        assert rep.institution_name
      end
    end
  end

  test "#hf" do
    build(:ht_ssd_proxy_report) do |rep|
      assert rep.hf
    end
  end
end
