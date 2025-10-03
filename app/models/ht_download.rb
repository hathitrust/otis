# frozen_string_literal: true

# Only used read-only in Otis for reporting
class HTDownload < ApplicationRecord

  # TODO change table name: ht_maintenance.otis_downloads
  # TODO scope by role, partial?, pages
  self.table_name = "ht_web.reports_downloads_ssdproxy"
  # default_scope { order(:datetime) }
  has_one :ht_hathifile, foreign_key: :htid, primary_key: :htid
  has_one :ht_institution, foreign_key: :inst_id, primary_key: :inst_code

  def self.ransackable_attributes(auth_object = nil)
    ["datetime", "email", "htid", "id", "in_copyright", "inst_code", "is_partial", "sha", "yyyy", "yyyymm"]
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

  ransacker :datetime do
    Arel.sql("DATE(#{table_name}.datetime)")
  end
end
