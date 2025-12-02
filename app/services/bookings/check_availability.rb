module Bookings
  class CheckAvailability
    def initialize(business:, service: nil, service_ids: nil, date:)
      @business = business
      @service = service
      @service_ids = service_ids ? Array(service_ids) : nil
      @date = date
    end

    def call
      # Get all slots for the date, ordered by start_time
      slots_for_day = @business.slots.for_date(@date).order(:start_time).to_a

      return [] if slots_for_day.empty?

      # Calculate how many consecutive slots needed
      slots_needed = calculate_slots_needed

      # Find all available start times
      available_start_times = []

      slots_for_day.each_cons(slots_needed) do |consecutive_slots|
        if all_consecutive_available?(consecutive_slots)
          available_start_times << consecutive_slots.first.start_time
        end
      end

      available_start_times
    end

    private

    def calculate_slots_needed
      total_duration = if @service
        @service.duration_minutes
      elsif @service_ids
        Service.where(id: @service_ids).sum(:duration_minutes)
      else
        0
      end

      (total_duration / 15.0).ceil
    end

    def all_consecutive_available?(slots)
      # Check if all slots have capacity > 0
      return false if slots.any? { |slot| slot.capacity <= 0 }

      # Check if slots are actually consecutive (no gaps)
      slots.each_cons(2).all? do |slot1, slot2|
        slot2.start_time == slot1.end_time
      end
    end
  end
end
