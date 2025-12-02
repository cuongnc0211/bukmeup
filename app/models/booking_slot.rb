class BookingSlot < ApplicationRecord
  belongs_to :booking
  belongs_to :slot

  # Validations
  validates :booking_id, :slot_id, presence: true
end
