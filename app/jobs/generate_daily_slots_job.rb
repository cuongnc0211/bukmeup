class GenerateDailySlotsJob < ApplicationJob
  queue_as :default

  def perform
    Business.find_each do |business|
      result = Slots::GenerateForBusiness.new(
        business: business,
        date: Date.tomorrow
      ).call

      Rails.logger.info("Slot generation for business #{business.id} (#{business.name}): #{result[:message]}")
    rescue StandardError => e
      Rails.logger.error("Failed to generate slots for business #{business.id}: #{e.message}")
      # Continue processing other businesses even if one fails
    end
  end
end
