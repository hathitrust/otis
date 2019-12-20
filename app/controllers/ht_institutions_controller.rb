# frozen_string_literal: true

class HTInstitutionsController < ApplicationController

  # Little helper
  class InstitutionWithCounts
    attr_accessor :active, :expired, :name
    def initialize
      @name = ""
      @active = 0
      @expired = 0
    end
  end

  def index
    insthash = Hash.new { |h, k| h[k] = InstitutionWithCounts.new }
    institutions = HTInstitution.preload(:ht_users).each_with_object(insthash) do |inst, h|
      h[inst.name].name = inst.name
      h[inst.name].active = inst.ht_users.count{|x| ! x.expired?}
      h[inst.name].expired = inst.ht_users.count{|x| ! x.expired?}
    end
    render action: :index, locals: {institutions: institutions.values.sort_by(&:name)}
  end
end
