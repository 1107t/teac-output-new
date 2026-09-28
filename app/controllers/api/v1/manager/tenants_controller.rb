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
  # テナントと、そのテナントの最初の管理者を同時に作成する。どちらかが不正なら両方とも作成しない。
  def create
    tenant = Tenant.new(tenant_params)
    admin = build_tenant_admin(tenant)

    errors = validation_errors(tenant, admin)
    return render json: { errors: errors }, status: :unprocessable_entity if errors.any?

    ActiveRecord::Base.transaction do
      tenant.save!
      admin.save!
    end
    render json: { tenant: tenant_json(tenant), admin: admin_json(admin) }, status: :created
  end

  private

  def set_tenant
    @tenant = Tenant.find_by(id: params[:id])
    render_not_found('テナント') unless @tenant
  end

  def tenant_params
    params.permit(:name)
  end

  def build_tenant_admin(tenant)
    admin = Admin.new(
      name: params[:admin_name],
      email: params[:admin_email],
      password: params[:admin_password],
      password_confirmation: params[:admin_password_confirmation],
      tenant: tenant,
      proaka: Proaka.order(:id).first
    )
    # マネージャーが作成するアカウントのため、確認メールをスキップして即有効化
    admin.skip_confirmation!
    admin
  end

  # Admin モデルは name を必須にしていないため、テナント作成時のみここで必須にする
  def validation_errors(tenant, admin)
    tenant.valid?
    admin.valid?
    admin.errors.add(:name, :blank) if admin.name.blank?
    tenant.errors.full_messages + admin.errors.full_messages
  end

  def tenant_json(tenant)
    {
      id: tenant.id.to_s,
      name: tenant.name,
      createdAt: tenant.created_at.iso8601
    }
  end
end
