# frozen_string_literal: true

RSpec.describe ApplicationHelper do
  let(:some_obj) { Class.new { include ApplicationHelper }.new }

  describe "#cache_bust_url" do
    it "appends a numeric version string" do
      expect(some_obj.cache_bust_url("scripts.js")).to match(/js\?v=\d+$/)
    end
  end
end
