# frozen_string_literal: true

class IPRestriction
  attr_reader :addrs

  def initialize(addrs = [])
    @addrs = addrs
  end

  def validate
    addrs.each do |addr|
      parsed = IPAddr.new(addr)
      raise ArgumentError, "#{addr} is an IPv6 address; only IPv4 addresses allowed" if parsed.ipv6?
      raise ArgumentError, "#{addr} is a private IPv4 address; only public addresses allowed" if parsed.private?
      raise ArgumentError, "#{addr} is a loopback IPv4 address; only public addresses allowed" if parsed.loopback?
    end
  end

  def self.any
    IPRestriction::Any.new
  end

  def self.unescape(regex)
    regex.gsub(/^\^/, '').gsub(/\$$/, '').gsub(/\\\./, '.')
  end

  def self.from_string(addrs)
    new(addrs.split(/\s*,\s*/).map(&:strip))
  end

  def self.from_regex(regex)
    case regex
    when nil
      nil
    when '^.*$'
      any
    else
      new(regex.split('|').map { |escaped| unescape(escaped) })
    end
  end

  def to_regex
    return unless addrs.any?

    addrs.map do |addr|
      '^' + Regexp.escape(addr) + '$'
    end.join('|')
  end
end

class IPRestriction::Any
  def to_regex
    '^.*$'
  end
end
