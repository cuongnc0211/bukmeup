require "rails_helper"

RSpec.describe Slot, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:business) }
    it { is_expected.to have_many(:booking_slots).dependent(:destroy) }
    it { is_expected.to have_many(:bookings).through(:booking_slots) }
  end

  describe "validations" do
    subject { build(:slot) }

    it { is_expected.to validate_presence_of(:start_time) }
    it { is_expected.to validate_presence_of(:end_time) }
    it { is_expected.to validate_presence_of(:date) }
    it { is_expected.to validate_presence_of(:capacity) }
    it { is_expected.to validate_presence_of(:original_capacity) }
    it { is_expected.to validate_numericality_of(:capacity).is_greater_than_or_equal_to(0) }
  end

  describe "scopes" do
    let(:business1) { create(:business) }
    let(:business2) { create(:business) }
    let(:date1) { Date.parse("2025-12-26") }
    let(:date2) { Date.parse("2025-12-27") }

    let!(:slot1) do
      create(:slot,
        business: business1,
        start_time: Time.zone.parse("2025-12-26 10:00"),
        end_time: Time.zone.parse("2025-12-26 10:15"),
        date: date1,
        capacity: 3)
    end

    let!(:slot2) do
      create(:slot,
        business: business1,
        start_time: Time.zone.parse("2025-12-26 10:15"),
        end_time: Time.zone.parse("2025-12-26 10:30"),
        date: date1,
        capacity: 0)
    end

    let!(:slot3) do
      create(:slot,
        business: business2,
        start_time: Time.zone.parse("2025-12-26 10:00"),
        end_time: Time.zone.parse("2025-12-26 10:15"),
        date: date1,
        capacity: 2)
    end

    let!(:slot4) do
      create(:slot,
        business: business1,
        start_time: Time.zone.parse("2025-12-27 10:00"),
        end_time: Time.zone.parse("2025-12-27 10:15"),
        date: date2,
        capacity: 3)
    end

    describe ".for_business" do
      it "returns slots for the specified business only" do
        expect(Slot.for_business(business1)).to contain_exactly(slot1, slot2, slot4)
      end

      it "excludes slots from other businesses" do
        expect(Slot.for_business(business1)).not_to include(slot3)
      end
    end

    describe ".for_date" do
      it "returns slots for the specified date only" do
        expect(Slot.for_date(date1)).to contain_exactly(slot1, slot2, slot3)
      end

      it "excludes slots from other dates" do
        expect(Slot.for_date(date1)).not_to include(slot4)
      end
    end

    describe ".available" do
      it "returns only slots with capacity > 0" do
        expect(Slot.available).to contain_exactly(slot1, slot3, slot4)
      end

      it "excludes slots with capacity = 0" do
        expect(Slot.available).not_to include(slot2)
      end
    end

    describe ".between" do
      it "returns slots within the specified time range" do
        start_time = Time.zone.parse("2025-12-26 10:00")
        end_time = Time.zone.parse("2025-12-26 10:30")

        slots = Slot.between(start_time, end_time)

        expect(slots).to contain_exactly(slot1, slot2, slot3)
      end

      it "excludes slots outside the time range" do
        start_time = Time.zone.parse("2025-12-27 09:00")
        end_time = Time.zone.parse("2025-12-27 11:00")

        slots = Slot.between(start_time, end_time)

        expect(slots).to include(slot4)
        expect(slots).not_to include(slot1, slot2, slot3)
      end

      it "can be combined with for_business scope" do
        start_time = Time.zone.parse("2025-12-26 10:00")
        end_time = Time.zone.parse("2025-12-26 10:30")

        slots = Slot.for_business(business1).between(start_time, end_time)

        expect(slots).to contain_exactly(slot1, slot2)
      end
    end
  end

  describe "database constraints" do
    let(:business) { create(:business) }
    let(:start_time) { Time.zone.parse("2025-12-26 10:00") }
    let(:end_time) { Time.zone.parse("2025-12-26 10:15") }

    it "prevents duplicate slots for same business and start_time" do
      create(:slot, business: business, start_time: start_time, end_time: end_time)

      expect {
        create(:slot, business: business, start_time: start_time, end_time: end_time)
      }.to raise_error(ActiveRecord::RecordNotUnique)
    end

    it "allows same start_time for different businesses" do
      business2 = create(:business)

      slot1 = create(:slot, business: business, start_time: start_time, end_time: end_time)
      slot2 = create(:slot, business: business2, start_time: start_time, end_time: end_time)

      expect(slot1).to be_persisted
      expect(slot2).to be_persisted
    end
  end
end
