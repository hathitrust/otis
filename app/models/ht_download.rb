# frozen_string_literal: true

# Read-only in the web interface.
# Written by log_import rake task.
class HTDownload < ApplicationRecord
  self.table_name = "ht_repository.otis_downloads"
  self.primary_key = "id"

  # default_scope { order(:datetime) }
  has_one :ht_hathifile, foreign_key: :htid, primary_key: :htid
  has_one :ht_institution, foreign_key: :inst_id, primary_key: :inst_code
  validates :sha, presence: true, uniqueness: true

  scope :for_role, ->(role) { where(role: role) }

  def self.ransackable_attributes(auth_object = nil)
    ["role", "datetime", "email", "htid", "id", "in_copyright", "inst_code", "sha", "yyyy", "yyyymm", "full_download", "pages", "seq"]
  end

  def self.ransackable_associations(auth_object = nil)
    ["ht_hathifile", "ht_institution"]
  end

  def institution_name
    institution&.name
  end

  def institution
    ht_institution
  end

  def hf
    ht_hathifile
  end

  def full_download
    !is_partial
  end

  ransacker :datetime do
    Arel.sql("DATE(#{table_name}.datetime)")
  end

  ransacker :full_download do
    Arel.sql("(CASE WHEN #{table_name}.is_partial = '0' THEN 'yes' WHEN #{table_name}.is_partial = '1' THEN 'no' END)")
  end

  def sha
    self[:sha] = calculate_sha
  end

  private

  # Should be equivalent enough to what was previous being done inside MariaDB:
  # UNHEX(SHA1(CONCAT_WS(' ', `datetime`, `htid`, `in_copyright`, `is_partial`, `email`, `inst_code`)))
  # Unhexing the data allows us to use binary(20) in the schema instead of varchar(40) but
  # it is unfriendly to look at.
  def calculate_sha
    input = [:datetime, :htid, :in_copyright, :is_partial, :email, :inst_code].map do |attr|
      self[attr].to_s
    end.join(" ")
    # Unhex: transform each hex representation into a character; see comments at
    # https://anthonylewis.com/2011/02/09/to-hex-and-back-with-ruby/
    [Digest::SHA1.hexdigest(input)].pack("H*")
  end
end
