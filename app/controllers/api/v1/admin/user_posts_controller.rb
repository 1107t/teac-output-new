# app/controllers/api/v1/admin/user_posts_controller.rb【新規作成】
# 管理者が特定の受講生の動画投稿一覧を閲覧するAPIコントローラー（読み取り専用）。
# 既存の Api::V1::Admin::TweetsController（つぶやき閲覧）と同じ構造で、user_id 配下にネストされる。
class Api::V1::Admin::UserPostsController < Api::V1::BaseController
  # admin ロールの JWT を必須とする（管理者専用エンドポイント）
  before_action :authenticate_admin!
  # URL の :user_id から対象の受講生を特定する
  before_action :set_target_user

  # GET /api/v1/admin/users/:user_id/posts
  # 指定した受講生の動画投稿を新着順（created_at 降順）で返す。
  # created_at が同一時刻（シードデータ等）でも並びが確定するよう id の降順を第2キーにする
  def index
    posts = @target_user.posts.order(created_at: :desc, id: :desc)
    render json: { posts: posts.map { |post| admin_post_json(post) } }
  end

  private

  # :user_id で受講生を検索し、存在しなければ 404 を返す
  def set_target_user
    @target_user = User.find_by(id: params[:user_id])
    render_not_found('ユーザー') unless @target_user
  end

  # フロント（AdminPost 型）が必要とするフィールドだけを返す管理者向け動画投稿JSON
  def admin_post_json(post)
    {
      id:         post.id.to_s,           # 動画投稿ID（文字列化してフロントの型と揃える）
      title:      post.title,             # 動画タイトル
      body:       post.body,              # 動画の説明本文（一覧ではプレビュー表示に使う）
      youtubeUrl: post.youtube_url,       # YouTubeのURL。未設定は null になり得る
      userId:     post.user_id&.to_s,     # 投稿者ID。詳細導線・デバッグ用に保持する
      createdAt:  post.created_at.iso8601 # 投稿日時（ISO 8601形式）
    }
  end
end
