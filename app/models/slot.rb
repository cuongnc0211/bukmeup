class Slot < ApplicationRecord
  belongs_to :business
  has_many :booking_slots, dependent: :destroy
  has_many :bookings, through: :booking_slots

  # Validations
  validates :start_time, :end_time, :date, :capacity, :original_capacity, presence: true
  validates :capacity, numericality: { greater_than_or_equal_to: 0 }

  # Scopes
  scope :for_business, ->(business) { where(business: business) }
  scope :for_date, ->(date) { where(date: date) }
  scope :available, -> { where("capacity > 0") }
  scope :between, ->(start_time, end_time) { where("start_time >= ? AND end_time <= ?", start_time, end_time) }
end
