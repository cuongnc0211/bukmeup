module Slots
  class GenerateForBusiness
    SLOT_DURATION = 15.minutes
    DAYS_AHEAD = 7

    def initialize(business:, date: nil)
      @business = business
      @date = date
    end

    def call
      if @date
        # Generate slots for a single date
        generate_slots_for_date(@date)
      else
        # Generate slots for next DAYS_AHEAD days
        generate_slots_for_range
      end
    end

    private

    def generate_slots_for_date(date)
      day_name = date.strftime("%A").downcase
      hours = @business.hours_for(day_name)

      # Skip if business is closed or no operating hours
      if hours.nil? || hours["closed"]
        return { success: true, slots_created: 0, message: "Business is closed on #{date}" }
      end

      slot_attributes = build_slot_attributes_for_date(date, hours)

      # Check for existing slots to avoid duplicates (idempotent)
      existing_slot_times = @business.slots.for_date(date).pluck(:start_time)
      new_slot_attributes = slot_attributes.reject do |attrs|
        existing_slot_times.include?(attrs[:start_time])
      end

      if new_slot_attributes.any?
        Slot.insert_all(new_slot_attributes)
      end

      {
        success: true,
        slots_created: new_slot_attributes.count,
        message: "#{new_slot_attributes.count} slots created for #{date}"
      }
    end

    def generate_slots_for_range
      total_created = 0

      DAYS_AHEAD.times do |day_offset|
        date = Date.current + day_offset.days
        result = generate_slots_for_date(date)
        total_created += result[:slots_created]
      end

      {
        success: true,
        slots_created: total_created,
        message: "#{total_created} slots created for next #{DAYS_AHEAD} days"
      }
    end

    def build_slot_attributes_for_date(date, hours)
      open_time = hours["open"]
      close_time = hours["close"]

      return [] if open_time.blank? || close_time.blank?

      opening_datetime = Time.zone.parse("#{date} #{open_time}")
      closing_datetime = Time.zone.parse("#{date} #{close_time}")

      slot_attributes = []
      current_time = opening_datetime

      while current_time < closing_datetime
        slot_attributes << {
          business_id: @business.id,
          start_time: current_time,
          end_time: current_time + SLOT_DURATION,
          date: date,
          capacity: @business.capacity,
          original_capacity: @business.capacity,
          created_at: Time.current,
          updated_at: Time.current
        }

        current_time += SLOT_DURATION
      end

      slot_attributes
    end
  end
end
