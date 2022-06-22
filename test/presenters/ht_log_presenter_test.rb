# frozen_string_literal: true

require "test_helper"

class HTLogPresenterTest < ActiveSupport::TestCase
  test "class constants" do
    assert_not_nil HTLogPresenter::ALL_FIELDS
    assert_equal 4, HTLogPresenter::ALL_FIELDS.count
  end

  test "#field_value :data" do
    log = HTLogPresenter.new(create(:ht_log))
    assert_match "<code>", log.field_value(:data)
  end

  test "#field_value :time" do
    log = HTLogPresenter.new(create(:ht_log))
    assert_match I18n.l(log.time, format: :long), log.field_value(:time)
    # Hidden field for sorting
    assert_match "display:none", log.field_value(:time)
  end
end
