class Api::V1::Auth::UsersController < Api::V1::BaseController
  skip_before_action :authenticate!, only: [:signup, :login]

  # POST /api/v1/auth/signup
  def signup
    user = User.new(signup_params)
    user.proaka ||= Proaka.order(:id).first
    # Devise の confirmable をスキップして即有効化
    user.skip_confirmation!

    if user.save
      if params[:birthday].present?
        user.create_profile(
          birthday: params[:birthday],
          registration_date: Date.today,
          hobby: ''
        )
      end
      token = JwtHelper.encode(id: user.id, role: 'user')
      render json: { token: token, user: user_json(user) }, status: :created
    else
      render json: { errors: user.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # POST /api/v1/auth/login
  def login
    user = User.find_by(email: params[:email]&.downcase, tenant_id: params[:tenant_id])
    if user&.valid_password?(params[:password])
      token = JwtHelper.encode(id: user.id, role: 'user')
      render json: { token: token, user: user_json(user) }
    else
      render json: { error: 'メールアドレスまたはパスワードが違います' }, status: :unauthorized
    end
  end

  # DELETE /api/v1/auth/logout
  def logout
    render json: { message: 'ログアウトしました' }
  end

  # GET /api/v1/auth/me
  def me
    render json: { user: user_json(@current_user) }
  end

  private

  def signup_params
    params.permit(:name, :email, :password, :password_confirmation, :gender, :tenant_id)
  end
end
