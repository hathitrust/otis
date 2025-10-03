# frozen_string_literal: true

require "test_helper"

class HTDownloadPresenterTest < ActiveSupport::TestCase
  test "class constants" do
    assert_not_nil HTDownloadPresenter::ALL_FIELDS
    assert_not_nil HTDownloadPresenter::DATA_FILTER_CONTROLS
    assert_not_nil HTDownloadPresenter::HF_FIELDS
  end

  test "each field has a data filter control" do
    HTDownloadPresenter::ALL_FIELDS.each do |field|
      assert_kind_of String, HTDownloadPresenter.data_filter_control(field)
    end
  end

  test "show page count" do
    report = HTDownloadPresenter.new(create(:ht_download, pages: rand(50..99)), action: :index)
    assert_includes HTDownloadPresenter::ALL_FIELDS, :pages
    assert_match(/\d+/, report.field_value(:pages))
  end

  test "hf fields have show methods" do
    report = HTDownloadPresenter.new(create(:ht_download), action: :index)
    HTDownloadPresenter::HF_FIELDS.each do |field|
      assert report.send(:"show_#{field}")
    end
  end

  test "hf show methods work for nonexistent hf entry" do
    report = create(:ht_download, :no_hf)
    report = HTDownloadPresenter.new(report, action: :index)
    HTDownloadPresenter::HF_FIELDS.each do |field|
      assert_equal report.send(:"show_#{field}"), ""
    end
  end

  test "show datetime" do
    report = HTDownloadPresenter.new(create(:ht_download), action: :index)
    assert_match(/\d\d\d\d-\d\d-\d\d/, report.field_value(:datetime))
  end

  test "show email" do
    report = HTDownloadPresenter.new(create(:ht_download), action: :index)
    assert_match "href=", report.field_value(:email)
  end

  test "show institution name" do
    create(:ht_download) do |rep|
      create(:ht_institution) do |inst|
        rep.inst_code = inst.inst_id
        report = HTDownloadPresenter.new(rep, action: :index)
        assert_match "href=", report.field_value(:institution_name)
      end
    end
  end
end
