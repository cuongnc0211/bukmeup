require "rails_helper"

RSpec.describe "Dashboard::Services", type: :request do
  let(:user) { create(:user) }
  let(:business) { create(:business, user: user) }
  let(:other_user) { create(:user, email_address: "other@example.com") }
  let(:other_business) { create(:business, user: other_user, slug: "other-shop") }

  # Helper to simulate logged in user
  def sign_in(user)
    post session_path, params: { email_address: user.email_address, password: "password123" }
  end

  describe "authentication" do
    it "redirects to login when not authenticated" do
      get dashboard_services_path
      expect(response).to redirect_to(new_session_path)
    end
  end

  describe "business setup requirement" do
    before { sign_in(user) }

    it "redirects to business setup when user has no business" do
      get dashboard_services_path
      expect(response).to redirect_to(new_dashboard_business_path)
    end
  end

  describe "GET /dashboard/services (index)" do
    before { sign_in(user) }

    it "lists all services for current user's business" do
      service1 = create(:service, business: business, name: "Haircut", position: 1)
      service2 = create(:service, business: business, name: "Shave", position: 2)
      other_service = create(:service, business: other_business, name: "Other Service")

      get dashboard_services_path
      expect(response).to have_http_status(:success)
      expect(response.body).to include("Haircut")
      expect(response.body).to include("Shave")
      expect(response.body).not_to include("Other Service")
    end

    it "orders services by position" do
      service2 = create(:service, business: business, name: "Service B", position: 2)
      service1 = create(:service, business: business, name: "Service A", position: 1)

      get dashboard_services_path
      expect(response).to have_http_status(:success)
      # Service A should appear before Service B in the response
      expect(response.body.index("Service A")).to be < response.body.index("Service B")
    end
  end

  describe "GET /dashboard/services/new" do
    before do
      sign_in(user)
      business # Ensure business exists
    end

    it "renders the new service form" do
      get new_dashboard_service_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "POST /dashboard/services (create)" do
    before do
      sign_in(user)
      business # Ensure business exists
    end

    context "with valid params" do
      let(:valid_params) do
        {
          service: {
            name: "Men's Haircut",
            description: "Professional haircut service",
            duration_minutes: 30,
            price: 80000 # In VND
          }
        }
      end

      it "creates a new service" do
        expect {
          post dashboard_services_path, params: valid_params
        }.to change(Service, :count).by(1)
      end

      it "associates service with current user's business" do
        post dashboard_services_path, params: valid_params
        expect(Service.last.business).to eq(business)
      end

      it "converts price to cents" do
        post dashboard_services_path, params: valid_params
        # 80,000 VND * 100 = 8,000,000 cents
        expect(Service.last.price_cents).to eq(8000000)
      end

      it "sets position to next available number" do
        existing_service = create(:service, business: business, name: "Existing Service", position: 5)

        post dashboard_services_path, params: valid_params

        business.reload
        new_service = business.services.where(name: "Men's Haircut").first
        expect(new_service).to be_present
        expect(new_service.position).to be > existing_service.position
      end

      it "redirects to services index with success message" do
        post dashboard_services_path, params: valid_params
        expect(response).to redirect_to(dashboard_services_path)
        follow_redirect!
        expect(response.body).to include("Service created successfully")
      end
    end

    context "with invalid params" do
      let(:invalid_params) do
        {
          service: {
            name: "",
            duration_minutes: 25, # Invalid duration
            price: -100 # Invalid price
          }
        }
      end

      it "does not create a service" do
        expect {
          post dashboard_services_path, params: invalid_params
        }.not_to change(Service, :count)
      end

      it "renders the new form with errors" do
        post dashboard_services_path, params: invalid_params
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe "GET /dashboard/services/:id/edit" do
    before { sign_in(user) }
    let(:service) { create(:service, business: business) }

    it "renders the edit service form" do
      get edit_dashboard_service_path(service)
      expect(response).to have_http_status(:success)
    end

    it "does not allow editing other business's services" do
      business # Ensure current user's business exists
      other_service = create(:service, business: other_business)
      get edit_dashboard_service_path(other_service)
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "PATCH /dashboard/services/:id (update)" do
    before { sign_in(user) }
    let(:service) { create(:service, business: business) }

    context "with valid params" do
      let(:valid_params) do
        {
          service: {
            name: "Updated Service Name",
            duration_minutes: 60,
            price: 120000
          }
        }
      end

      it "updates the service" do
        patch dashboard_service_path(service), params: valid_params
        service.reload
        expect(service.name).to eq("Updated Service Name")
        expect(service.duration_minutes).to eq(60)
        expect(service.price_cents).to eq(12000000) # 120,000 * 100
      end

      it "redirects to services index with success message" do
        patch dashboard_service_path(service), params: valid_params
        expect(response).to redirect_to(dashboard_services_path)
        follow_redirect!
        expect(response.body).to include("Service updated successfully")
      end
    end

    context "with invalid params" do
      let(:invalid_params) do
        {
          service: {
            name: "",
            duration_minutes: 999
          }
        }
      end

      it "does not update the service" do
        original_name = service.name
        patch dashboard_service_path(service), params: invalid_params
        service.reload
        expect(service.name).to eq(original_name)
      end

      it "renders the edit form with errors" do
        patch dashboard_service_path(service), params: invalid_params
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    it "does not allow updating other business's services" do
      business # Ensure current user's business exists
      other_service = create(:service, business: other_business)
      patch dashboard_service_path(other_service), params: { service: { name: "Hacked" } }
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "DELETE /dashboard/services/:id (destroy)" do
    before { sign_in(user) }
    let!(:service) { create(:service, business: business) }

    it "deletes the service" do
      expect {
        delete dashboard_service_path(service)
      }.to change(Service, :count).by(-1)
    end

    it "redirects to services index with success message" do
      delete dashboard_service_path(service)
      expect(response).to redirect_to(dashboard_services_path)
      follow_redirect!
      expect(response.body).to include("Service deleted successfully")
    end

    it "does not allow deleting other business's services" do
      business # Ensure current user's business exists
      other_service = create(:service, business: other_business)
      expect {
        delete dashboard_service_path(other_service)
      }.not_to change(Service, :count)
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "POST /dashboard/services/:id/move_up" do
    before { sign_in(user) }

    it "moves service up in order" do
      service1 = create(:service, business: business, position: 1, name: "Service 1")
      service2 = create(:service, business: business, position: 2, name: "Service 2")

      post move_up_dashboard_service_path(service2)

      service1.reload
      service2.reload
      expect(service2.position).to eq(1)
      expect(service1.position).to eq(2)
    end

    it "does nothing when service is already first" do
      service = create(:service, business: business, position: 1)

      post move_up_dashboard_service_path(service)

      service.reload
      expect(service.position).to eq(1)
    end

    it "redirects back to services index" do
      service = create(:service, business: business, position: 2)
      post move_up_dashboard_service_path(service)
      expect(response).to redirect_to(dashboard_services_path)
    end

    it "does not allow moving other business's services" do
      business # Ensure current user's business exists
      other_service = create(:service, business: other_business, position: 2)
      post move_up_dashboard_service_path(other_service)
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "POST /dashboard/services/:id/move_down" do
    before { sign_in(user) }

    it "moves service down in order" do
      service1 = create(:service, business: business, position: 1, name: "Service 1")
      service2 = create(:service, business: business, position: 2, name: "Service 2")

      post move_down_dashboard_service_path(service1)

      service1.reload
      service2.reload
      expect(service1.position).to eq(2)
      expect(service2.position).to eq(1)
    end

    it "does nothing when service is already last" do
      service = create(:service, business: business, position: 1)

      post move_down_dashboard_service_path(service)

      service.reload
      expect(service.position).to eq(1)
    end

    it "redirects back to services index" do
      service = create(:service, business: business, position: 1)
      post move_down_dashboard_service_path(service)
      expect(response).to redirect_to(dashboard_services_path)
    end

    it "does not allow moving other business's services" do
      business # Ensure current user's business exists
      other_service = create(:service, business: other_business, position: 1)
      post move_down_dashboard_service_path(other_service)
      expect(response).to have_http_status(:not_found)
    end
  end
end
