module Dashboard
  class BaseController < ApplicationController
    # All controllers in Dashboard namespace require authentication
    # (inherited from ApplicationController's require_authentication before_action)

    layout "dashboard"

    # Require business setup before accessing other dashboard pages
    before_action :require_business_setup

    private

    def require_business_setup
      # Skip this check for BusinessesController (so users can create their business)
      return if self.class.name == "Dashboard::BusinessesController"

      if current_user.business.nil?
        redirect_to new_dashboard_business_path, alert: "Please set up your business first."
      end
    end
  end
end
