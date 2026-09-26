class Api::V1::BaseController < ActionController::API
  before_action :authenticate!

  private

  def authenticate!
    token = request.headers['Authorization']&.split(' ')&.last
    return render_unauthorized unless token

    payload = JwtHelper.decode(token)
    return render_unauthorized unless payload

    role = payload['role']
    id   = payload['id']

    @current_user    = User.find_by(id: id)    if role == 'user'
    @current_admin   = Admin.find_by(id: id)   if role == 'admin'
    @current_manager = Manager.find_by(id: id) if role == 'manager'

    authenticated = @current_user || @current_admin || @current_manager
    return render_unauthorized unless authenticated && token_tenant_matches?(authenticated, payload)

    # 以降このリクエスト内で行われる User/Admin へのクエリは、
    # 自動的に自分のテナントの範囲内に絞り込まれる（他テナントのデータには
    # アプリケーションレベルで一切アクセスできない）。managerはテナントに
    # 紐付かないため current_tenant は nil のままとなり、絞り込みは行われない。
    Current.tenant = current_tenant
  end

  # ログイン中のuser/adminが所属するテナントをRails側で判定する。
  # URLやリクエストパラメータのtenant_idを信用せず、認証済みレコード自身の
  # tenant_id を正とすることで、どのテナントからのリクエストかを特定する。
  def current_tenant
    @current_user&.tenant || @current_admin&.tenant
  end

  def authenticate_user!
    token = request.headers['Authorization']&.split(' ')&.last
    return render_unauthorized unless token

    payload = JwtHelper.decode(token)
    return render_unauthorized unless payload && payload['role'] == 'user'

    @current_user = User.find_by(id: payload['id'])
    render_unauthorized unless @current_user && token_tenant_matches?(@current_user, payload)
  end

  def authenticate_admin!
    token = request.headers['Authorization']&.split(' ')&.last
    return render_unauthorized unless token

    payload = JwtHelper.decode(token)
    return render_unauthorized unless payload && payload['role'] == 'admin'

    @current_admin = Admin.find_by(id: payload['id'])
    render_unauthorized unless @current_admin && token_tenant_matches?(@current_admin, payload)
  end

  def authenticate_manager!
    token = request.headers['Authorization']&.split(' ')&.last
    return render_unauthorized unless token

    payload = JwtHelper.decode(token)
    return render_unauthorized unless payload && payload['role'] == 'manager'

    @current_manager = Manager.find_by(id: payload['id'])
    render_unauthorized unless @current_manager
  end

  # user/admin のトークンには発行時の tenant_id が入っている。所属テナントが
  # 変わった後や tenant_id を持たない古いトークンは無効として扱う。
  # manager はテナントに紐付かないため確認しない。
  def token_tenant_matches?(record, payload)
    return true if record.is_a?(Manager)

    payload['tenant_id'].present? && payload['tenant_id'].to_s == record.tenant_id.to_s
  end

  def render_unauthorized
    render json: { error: '認証が必要です' }, status: :unauthorized
  end

  def render_not_found(resource = 'リソース')
    render json: { error: "#{resource}が見つかりません" }, status: :not_found
  end

  def user_json(user)
    profile = user.profile
    {
      id: user.id.to_s,
      name: user.name,
      email: user.email,
      birthday: profile&.birthday&.strftime('%Y-%m-%d'),
      gender: user.gender,
      tenantId: user.tenant_id.to_s,
      createdAt: user.created_at.iso8601
    }
  end

  def admin_json(admin)
    {
      id: admin.id.to_s,
      name: admin.name,
      email: admin.email,
      tenantId: admin.tenant_id.to_s,
      createdAt: admin.created_at.iso8601
    }
  end

  def manager_json(manager)
    {
      id: manager.id.to_s,
      name: manager.name,
      email: manager.email,
      createdAt: manager.created_at.iso8601
    }
  end
end
