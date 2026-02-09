# frozen_string_literal: true

RSpec.describe ApplicationPresenter do
  describe ".data_cookie_expire" do
    # All of the model-specific presenters inherit the default implementation.
    # We just check that the value is a String with a value "N+d" since although
    # we may change the TTL we are highly unlikely to change "days" as choice of units.
    it "is a String with one or more digits ending in 'd'" do
      expect(described_class.data_cookie_expire).to be_a(String)
      expect(described_class.data_cookie_expire).to match(/\d+d/)
    end
  end
end
