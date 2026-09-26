class Api::V1::Auth::AdminsController < Api::V1::BaseController
  skip_before_action :authenticate!, only: [:login]

  # POST /api/v1/admin/auth/login
  def login
    admin = Admin.find_by(email: params[:email]&.downcase)
    if admin&.valid_password?(params[:password])
      token = JwtHelper.encode(id: admin.id, role: 'admin', tenant_id: admin.tenant_id)
      render json: { token: token, admin: admin_json(admin) }
    else
      render json: { error: 'メールアドレスまたはパスワードが違います' }, status: :unauthorized
    end
  end

  # DELETE /api/v1/admin/auth/logout
  def logout
    render json: { message: 'ログアウトしました' }
  end

  # GET /api/v1/admin/auth/me
  def me
    render json: { admin: admin_json(@current_admin) }
  end
end
