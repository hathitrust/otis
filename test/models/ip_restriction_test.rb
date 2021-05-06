# frozen_string_literal: true

require "test_helper"

class IPRestrictionTest < ActiveSupport::TestCase
  test "turns a single valid string-formatted IPv4 address into a regular expression" do
    assert_equal('^1\.2\.3\.4$', IPRestriction.new(["1.2.3.4"]).to_regex)
  end

  test "turns multiple valid string-formatted IPv4 addresses into a regular expression" do
    assert_equal('^1\.2\.3\.4$|^5\.6\.7\.8$', IPRestriction.new(["1.2.3.4", "5.6.7.8"]).to_regex)
  end

  test "returns nil when there are no addresses" do
    assert_nil(IPRestriction.new.to_regex)
  end

  test "rejects out-of-range IPs" do
    assert_raises ArgumentError do
      IPRestriction.new(["256.257.258.259"]).validate
    end
  end

  test "rejects IPv6 IPs" do
    assert_raises ArgumentError do
      IPRestriction.new(["2001:1234::1"]).validate
    end
  end

  test "rejects non-public IPs" do
    assert_raises ArgumentError do
      IPRestriction.new(["10.1.2.3"]).validate
    end
  end

  test "rejects loopback IPs" do
    assert_raises ArgumentError do
      IPRestriction.new(["127.0.0.1"]).validate
    end
  end
end

class IPRestrictionFromStringTest < ActiveSupport::TestCase
  test "can parse a string" do
    assert_equal(["1.2.3.4"], IPRestriction.from_string("1.2.3.4").addrs)
  end

  test "can parse a string with multiple IPs" do
    assert_equal(["1.2.3.4", "5.6.7.8"], IPRestriction.from_string("1.2.3.4,5.6.7.8").addrs)
  end

  test "can parse a string with whitespace" do
    assert_equal(["1.2.3.4"], IPRestriction.from_string(" 1.2.3.4 ").addrs)
  end

  test "can parse the any string" do
    assert_instance_of(IPRestriction::Any, IPRestriction.from_string("any"))
  end
end

class IPRestrictionFromRegexTest < ActiveSupport::TestCase
  test "can parse a regex matching any IP" do
    assert_instance_of(IPRestriction::Any, IPRestriction.from_regex("^.*$"))
  end

  test "raises ArgumentError for unparseable nonsense" do
    assert_raises ArgumentError do
      IPRestriction.from_regex("this is not an IP address").validate
    end
  end

  test "returns nil with a nil regex" do
    assert_nil(IPRestriction.from_regex(nil))
  end

  test "can round-trip a single IP" do
    regex = '^1\.2\.3\.4$'
    assert_equal regex, IPRestriction.from_regex(regex).to_regex
  end

  test "can round-trip multiple IPs" do
    regex = '^1\.2\.3\.4$|^5\.6\.7\.8$'
    assert_equal regex, IPRestriction.from_regex(regex).to_regex
  end
end

class IPRestrictionAnyTest < ActiveSupport::TestCase
  test "converts to a regex matching anything" do
    assert_equal("^.*$", IPRestriction.any.to_regex)
  end

  test "converts to the any string" do
    assert_equal(["any"], IPRestriction.any.addrs)
  end
end
