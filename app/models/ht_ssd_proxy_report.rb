# frozen_string_literal: true

# Only used read-only in Otis for reporting
class HTSSDProxyReport < ApplicationRecord
  self.table_name = "ht_web.reports_downloads_ssdproxy"
  default_scope { order(:datetime) }
  belongs_to :ht_hathifile, foreign_key: :htid, primary_key: :htid

  def institution_name
    @institution_name ||= HTInstitution.where(inst_id: inst_code)&.first&.name
  end

  def hf
    @hf = ht_hathifile
  end
end
