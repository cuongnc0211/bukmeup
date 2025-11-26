module Dashboard
  class ServicesController < BaseController
    before_action :set_service, only: [ :edit, :update, :destroy, :move_up, :move_down ]

    def index
      @services = current_user.business.services.order(:position)
    end

    def new
      @service = current_user.business.services.build
    end

    def create
      @service = current_user.business.services.build(service_params)

      # Set position to next available number
      max_position = current_user.business.services.maximum(:position) || 0
      @service.position = max_position + 1

      if @service.save
        redirect_to dashboard_services_path, notice: "Service created successfully."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      # Convert price from VND to cents (multiply by 100)
      if params[:service][:price].present?
        @service.price_cents = (params[:service][:price].to_f * 100).to_i
      end

      if @service.update(service_params_without_price)
        redirect_to dashboard_services_path, notice: "Service updated successfully."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @service.destroy
      redirect_to dashboard_services_path, notice: "Service deleted successfully."
    end

    def move_up
      # Find the service immediately above (lower position number)
      previous_service = current_user.business.services
                                     .where("position < ?", @service.position)
                                     .order(position: :desc)
                                     .first

      if previous_service
        # Swap positions
        @service.position, previous_service.position = previous_service.position, @service.position
        @service.save
        previous_service.save
      end

      redirect_to dashboard_services_path
    end

    def move_down
      # Find the service immediately below (higher position number)
      next_service = current_user.business.services
                                 .where("position > ?", @service.position)
                                 .order(position: :asc)
                                 .first

      if next_service
        # Swap positions
        @service.position, next_service.position = next_service.position, @service.position
        @service.save
        next_service.save
      end

      redirect_to dashboard_services_path
    end

    private

    def set_service
      @service = current_user.business.services.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      head :not_found
    end

    def service_params
      params.require(:service).permit(:name, :description, :duration_minutes, :active)
    end

    def service_params_without_price
      params.require(:service).permit(:name, :description, :duration_minutes, :active)
    end
  end
end
