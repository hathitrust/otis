# frozen_string_literal: true

class ApplicationRecord < ActiveRecord::Base
  include Otis::Authorization::Resource

  self.abstract_class = true
  # https://github.com/rmm5t/strip_attributes
  strip_attributes
end
