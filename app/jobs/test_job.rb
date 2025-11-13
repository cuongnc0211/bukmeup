class TestJob < ApplicationJob
  queue_as :default

  def perform(*args)
    # Do something later
    Rails.logger.info "Solid Queue is working! Args: #{args.inspect}"
  end
end
