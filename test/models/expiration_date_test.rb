# frozen_string_literal: true

require 'test_helper'

class ExpirationDateTest < ActiveSupport::TestCase
  def setup
    @jan1      = ExpirationDate.new('2020-01-01 11:11:11', :expiresannually)
    @plus10    = ExpirationDate.new((Date.today + 10), :expiresannually)
    @minus10   = ExpirationDate.new((Date.today - 10), :expiresannually)
    @yearsaway = ExpirationDate.new((Date.today + 700), :expiresannuyally)

    @annual   = @jan1
    @custom60 = ExpirationDate.new(Date.today, :expirescustom60)
  end

  test 'Create a simple object and get back strings' do
    assert_equal '2020-01-01', @jan1.short_string
    assert_equal '2020-01-01', @jan1.to_s
  end

  test 'Determine days until expiration' do
    assert_equal 10, @plus10.days_until_expiration
  end

  test 'Boolean tests about expiration' do
    assert @plus10.expiring_soon?
    assert_not @plus10.expired?
    assert @minus10.expired?
    assert_not @yearsaway.expiring_soon?
    assert_not @minus10.expiring_soon?
  end

  test 'Expiration extension' do
    assert_equal Date.parse('2021-01-01'), @annual.default_extension_date.to_date
    assert_equal Date.today + 60, @custom60.default_extension_date.to_date
    assert_equal '1 year', @annual.extension_period_text
    assert_equal '60 days', @custom60.extension_period_text
  end

  test 'Equality' do
    eq1 = ExpirationDate.new('2019-01-01', :expiresannually)
    eq2 = ExpirationDate.new('2019-01-01', :expiresannually)
    eq3 = ExpirationDate.new('2019-01-01', :expirescustom60)
    neq = ExpirationDate.new('2022-02-02', :expiresannually)

    assert_equal(eq1, eq2)
    assert_equal(eq1, eq3)
    assert_not_equal(eq1, neq)
  end
end
