# frozen_string_literal: true

RSpec.describe Otis::Service do
  describe "#name" do
    HTRegistration::ROLES.each do |role|
      it "gets service role name for `HTRegistration` role #{role}" do
        expect(described_class.new(role).name).not_to eq(nil)
      end
    end

    HTRegistration::ROLES.each do |role|
      it "gets service role full name for `HTRegistration` role #{role}" do
        expect(described_class.new(role).full_name).not_to eq(nil)
      end
    end
  end
end
