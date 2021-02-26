# frozen_string_literal: true

class HTBillingMember < ApplicationRecord
  belongs_to :ht_institution, foreign_key: 'inst_id', optional: true

  self.primary_key = 'inst_id'
end
