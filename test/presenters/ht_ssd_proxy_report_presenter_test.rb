# frozen_string_literal: true

require "test_helper"

class HTSSDProxyReportPresenterTest < ActiveSupport::TestCase
  test "class constants" do
    assert_not_nil HTSSDProxyReportPresenter::ALL_FIELDS
    assert_not_nil HTSSDProxyReportPresenter::DATA_FILTER_CONTROLS
    assert_not_nil HTSSDProxyReportPresenter::HF_FIELDS
  end

  test "each field has a data filter control" do
    HTSSDProxyReportPresenter::ALL_FIELDS.each do |field|
      assert_kind_of String, HTSSDProxyReportPresenter.data_filter_control(field)
    end
  end

  test "hf fields have show methods" do
    report = HTSSDProxyReportPresenter.new(create(:ht_ssd_proxy_report), action: :index)
    HTSSDProxyReportPresenter::HF_FIELDS.each do |field|
      assert report.send("show_#{field}")
    end
  end

  test "hf show methods work for nonexistent hf entry" do
    report = create(:ht_ssd_proxy_report, :no_hf)
    report = HTSSDProxyReportPresenter.new(report, action: :index)
    HTSSDProxyReportPresenter::HF_FIELDS.each do |field|
      assert_equal report.send("show_#{field}"), ""
    end
  end

  test "show datetime" do
    report = HTSSDProxyReportPresenter.new(create(:ht_ssd_proxy_report), action: :index)
    assert_match(/\d\d\d\d-\d\d-\d\d/, report.field_value(:datetime))
  end

  test "show email" do
    report = HTSSDProxyReportPresenter.new(create(:ht_ssd_proxy_report), action: :index)
    assert_match "href=", report.field_value(:email)
  end

  test "show institution name" do
    create(:ht_ssd_proxy_report) do |rep|
      create(:ht_institution) do |inst|
        rep.inst_code = inst.inst_id
        report = HTSSDProxyReportPresenter.new(rep, action: :index)
        assert_match "href=", report.field_value(:institution_name)
      end
    end
  end
end
