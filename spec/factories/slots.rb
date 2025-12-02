FactoryBot.define do
  factory :slot do
    business
    start_time { Time.zone.parse("2025-12-26 10:00") }
    end_time { Time.zone.parse("2025-12-26 10:15") }
    date { Date.parse("2025-12-26") }
    capacity { 3 }
    original_capacity { 3 }

    trait :full do
      capacity { 0 }
    end

    trait :partially_booked do
      capacity { 1 }
      original_capacity { 3 }
    end

    trait :different_time do
      start_time { Time.zone.parse("2025-12-26 14:00") }
      end_time { Time.zone.parse("2025-12-26 14:15") }
    end

    trait :tomorrow do
      start_time { 1.day.from_now.change(hour: 10, min: 0) }
      end_time { 1.day.from_now.change(hour: 10, min: 15) }
      date { 1.day.from_now.to_date }
    end

    # Generate sequence of consecutive 15-min slots
    trait :sequence do
      transient do
        sequence_start { Time.zone.parse("2025-12-26 09:00") }
        sequence_count { 4 }
      end

      after(:create) do |slot, evaluator|
        (1...evaluator.sequence_count).each do |i|
          offset = i * 15.minutes
          create(:slot,
            business: slot.business,
            start_time: evaluator.sequence_start + offset,
            end_time: evaluator.sequence_start + offset + 15.minutes,
            date: evaluator.sequence_start.to_date,
            capacity: slot.capacity,
            original_capacity: slot.original_capacity)
        end
      end
    end
  end
end
