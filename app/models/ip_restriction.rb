# frozen_string_literal: true

class IPRestrictionError < StandardError
  attr_reader :type, :address
  TYPES = %i[invalid ipv6 private loopback].freeze

  def initialize(msg = "IP Restriction Error", type:, address:)
    @type = type
    @address = address
    super msg
  end
end

class IPRestriction
  attr_reader :addrs

  def initialize(addrs = [])
    @addrs = addrs
  end

  def validate
    addrs.each do |addr|
      begin
        parsed = IPAddr.new(addr)
      rescue IPAddr::InvalidAddressError
        raise IPRestrictionError.new(type: :invalid, address: addr)
      end
      raise IPRestrictionError.new(type: :ipv6, address: addr) if parsed.ipv6?
      raise IPRestrictionError.new(type: :private, address: addr) if parsed.private?
      raise IPRestrictionError.new(type: :loopback, address: addr) if parsed.loopback?
    end
  end

  def self.any
    IPRestriction::Any.new
  end

  def self.unescape(regex)
    regex.gsub(/^\^/, "").gsub(/\$$/, "").gsub(/\\\./, ".")
  end

  def self.from_string(addrs)
    if addrs == "any"
      any
    else
      new(addrs.split(/\s*,\s*/).map(&:strip))
    end
  end

  def self.from_regex(regex)
    case regex
    when nil
      nil
    when "^.*$"
      any
    else
      new(regex.split("|").map { |escaped| unescape(escaped) })
    end
  end

  def to_regex
    return unless addrs.any?

    addrs.map do |addr|
      "^" + Regexp.escape(addr) + "$"
    end.join("|")
  end
end

class IPRestriction::Any
  def to_regex
    "^.*$"
  end

  def addrs
    ["any"]
  end

  def validate
  end
end
