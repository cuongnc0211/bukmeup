require "rails_helper"

RSpec.describe BookingSlot, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:booking) }
    it { is_expected.to belong_to(:slot) }
  end

  describe "validations" do
    subject { build(:booking_slot) }

    it { is_expected.to validate_presence_of(:booking_id) }
    it { is_expected.to validate_presence_of(:slot_id) }
  end

  describe "database constraints" do
    let(:booking) { create(:booking) }
    let(:slot) { create(:slot) }

    it "prevents duplicate booking_slot for same booking and slot" do
      create(:booking_slot, booking: booking, slot: slot)

      expect {
        create(:booking_slot, booking: booking, slot: slot)
      }.to raise_error(ActiveRecord::RecordNotUnique)
    end

    it "allows same slot to be linked to different bookings" do
      booking2 = create(:booking)

      booking_slot1 = create(:booking_slot, booking: booking, slot: slot)
      booking_slot2 = create(:booking_slot, booking: booking2, slot: slot)

      expect(booking_slot1).to be_persisted
      expect(booking_slot2).to be_persisted
    end

    it "allows same booking to be linked to different slots" do
      slot2 = create(:slot)

      booking_slot1 = create(:booking_slot, booking: booking, slot: slot)
      booking_slot2 = create(:booking_slot, booking: booking, slot: slot2)

      expect(booking_slot1).to be_persisted
      expect(booking_slot2).to be_persisted
    end
  end
end
