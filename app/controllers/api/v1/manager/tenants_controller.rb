class Api::V1::Manager::TenantsController < Api::V1::BaseController
  before_action :authenticate_manager!
  before_action :set_tenant, only: [:show]

  # GET /api/v1/manager/tenants
  def index
    tenants = Tenant.order(created_at: :desc)
    render json: { tenants: tenants.map { |t| tenant_json(t) } }
  end

  # GET /api/v1/manager/tenants/:id
  def show
    render json: { tenant: tenant_json(@tenant) }
  end

  # POST /api/v1/manager/tenants
  def create
    tenant = Tenant.new(tenant_params)
    if tenant.save
      render json: { tenant: tenant_json(tenant) }, status: :created
    else
      render json: { errors: tenant.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def set_tenant
    @tenant = Tenant.find_by(id: params[:id])
    render_not_found('テナント') unless @tenant
  end

  def tenant_params
    params.permit(:name)
  end

  def tenant_json(tenant)
    {
      id: tenant.id.to_s,
      name: tenant.name,
      createdAt: tenant.created_at.iso8601
    }
  end
end
