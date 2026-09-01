# frozen_string_literal: true

RSpec.describe HTContact do
  let(:factory) { :ht_contact_type }

  describe "validations" do
    describe "name" do
      it "must be present" do
        expect(build(factory, name: nil).valid?).to be false
        expect(build(factory, name: "").valid?).to be false
        expect(build(factory, name: "Test Name").valid?).to be true
      end
    end
  end
end
