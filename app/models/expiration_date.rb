# frozen_string_literal: true

class ExpirationDate
  include Comparable

  # What text describes the extension period?
  # Build them up from a little helper class
  class ExpiresTypeData
    attr_reader :duration, :label

    def initialize(label, duration)
      @duration = duration
      @label = label
    end

    def to_s
      @label
    end
  end

  EXPIRES_TYPE = {
    expiresannually: ExpiresTypeData.new("1 year", 1.year).freeze,
    expiresbiannually: ExpiresTypeData.new("2 years", 2.years).freeze,
    expirescustom60: ExpiresTypeData.new("60 days", 60.days).freeze,
    expirescustom90: ExpiresTypeData.new("90 days", 90.days).freeze
  }.freeze

  # Shared utility for converting a (mostly) arbitrary value into a Date.
  def self.convert_to_date(obj)
    if obj.respond_to? :to_date
      obj.to_date
    else
      Time.zone.parse(obj.to_s).to_date
    end
  end

  # An expiration date is an actually two things:
  # * a date (returned from ActiveRecord as an ActiveSupport::TimeWithZone,
  #   which stringifies nicely into something Date.parse can deal with)
  # * A symbol representing the expiration policy
  #
  # @param [String, #to_datetime, #to_date] date String representation of the date.
  #   This is always truncated to just the date (see  https://hathitrust.slack.com/archives/DKV93G37T/p1576770049002400)
  # @param [String,Symbol] type The expires_type to use
  def initialize(date, type = :expiresannually)
    @date = self.class.convert_to_date(date).freeze
    @expires_type = type.to_sym
  end

  def to_date
    @date.to_date
  end

  ### NOTE ###
  #  Asked Melissa if we'd ever need granularity beyond the date level,
  #  and she says no. https://hathitrust.slack.com/archives/DKV93G37T/p1576770049002400
  # Long version of the date string
  # @return [String] date string
  # def database_string
  #   @date.to_s(:db)
  # end

  # Short version of the date string
  # @return [String] YYYY-MM-DD
  def short_string
    @date.strftime "%Y-%m-%d"
  end

  alias_method :to_s, :short_string

  # How many days until expiration?
  # @return [Number] days until expiration
  def days_until_expiration
    (@date.to_date - Date.today).to_i
  end

  # Is this person expiring "soon" (based on the config)?
  # @return [Boolean]
  def expiring_soon?
    days_until_expiration.between? 0, (Otis.config&.expires_soon_in_days || 30)
  end

  # Are we, in fact, already expired?
  # @return [Boolean]
  def expired?
    days_until_expiration.negative?
  end

  # What text describes the extension period?
  # @return [String] A human readable extension period (.e.g, "1 year")
  # FIXME: on the chopping block in favor of localization
  # This is used by the approval request mailer which is not yet really locale-aware.
  def extension_period_text
    EXPIRES_TYPE[@expires_type].label
  end

  # The date if we advance the expiration date  by the default amount
  # @return [ActiveSupport::TimeWithZone] The new expiration date
  def default_extension_date
    @date + EXPIRES_TYPE[@expires_type].duration
  rescue NoMethodError => e
    raise e
  end

  # For comparisons, just check the date
  # @param [#to_date, String] other Any object that can turn itself into a date,
  #  or a string that can be parsed by Time.zone.parse
  # @return [Integer] Normal <=> return indicating (in)equality of the dates only
  def <=>(other)
    to_date <=> self.class.convert_to_date(other)
  end
end
