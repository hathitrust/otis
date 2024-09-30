# frozen_string_literal: true

# Used as a secondary source of information for SSD Proxy Reports
# Only fleshed out to the extent needed. There's a lot we could do here.
class HTHathifile < ApplicationRecord
  self.table_name = "hathifiles.hf"
  self.primary_key = "htid"
  has_many :ht_ssd_proxy_report, foreign_key: :htid, primary_key: :htid

  # SSD Proxy Reports uses Ransack gem to search by association
  def self.ransackable_attributes(auth_object = nil)
    %w[
      author bib_num content_provider_code digitization_agent_code htid imprint
      rights_code rights_date_used title
    ]
  end

  def self.ransackable_associations(auth_object = nil)
    %w[ht_ssd_proxy_report]
  end

  private

  # Ransack search matchers assume string values, so convert this integer
  ransacker :bib_num do
    Arel.sql("CONVERT(#{table_name}.bib_num, CHAR(9))")
  end
end
