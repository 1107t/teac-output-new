# spec/requests/api/v1/admin/user_posts_spec.rb
# 管理者が特定の受講生の動画投稿一覧を閲覧するエンドポイントの request spec。
# GET /api/v1/admin/users/:user_id/posts の正常系・認証・認可・存在しないユーザーを検証する。
require 'rails_helper'

RSpec.describe 'Api::V1::Admin::UserPosts', type: :request do
  # 管理者トークンを Authorization ヘッダー形式で組み立てるヘルパー
  def admin_auth_headers(admin)
    { 'Authorization' => "Bearer #{JwtHelper.encode(id: admin.id, role: 'admin', tenant_id: admin.tenant_id)}" }
  end

  # ユーザートークン（admin ロール以外）を組み立てるヘルパー。認可エラー検証に使う
  def user_auth_headers(user)
    { 'Authorization' => "Bearer #{JwtHelper.encode(id: user.id, role: 'user', tenant_id: user.tenant_id)}" }
  end

  let(:admin) { create(:admin) }
  # 対象の受講生と、投稿が混ざらないことを確認するための別の受講生（管理者と同じテナントに所属させる）
  let(:target_user) { create(:user, tenant: admin.tenant) }
  let(:other_user) { create(:user, tenant: admin.tenant) }

  describe 'GET /api/v1/admin/users/:user_id/posts' do
    context '管理者として認証済みの場合' do
      # 対象ユーザーの動画投稿を作成日時のバラつきを持たせて3件、別ユーザーの投稿を1件用意する
      let!(:older_post) { create(:post, user: target_user, created_at: 2.days.ago) }
      let!(:newer_post) { create(:post, user: target_user, created_at: 1.day.ago) }
      let!(:newest_post) { create(:post, user: target_user, created_at: Time.current) }
      let!(:other_users_post) { create(:post, user: other_user) }

      it '対象ユーザーの動画投稿だけを返す（他ユーザーの投稿は含まない）' do
        get "/api/v1/admin/users/#{target_user.id}/posts", headers: admin_auth_headers(admin)

        expect(response).to have_http_status(:ok)
        body = JSON.parse(response.body)
        returned_ids = body['posts'].map { |post| post['id'] }
        expect(returned_ids).to contain_exactly(
          older_post.id.to_s, newer_post.id.to_s, newest_post.id.to_s
        )
        expect(returned_ids).not_to include(other_users_post.id.to_s)
      end

      it '新着順（created_at の降順）で返す' do
        get "/api/v1/admin/users/#{target_user.id}/posts", headers: admin_auth_headers(admin)

        body = JSON.parse(response.body)
        returned_ids = body['posts'].map { |post| post['id'] }
        expect(returned_ids).to eq([
          newest_post.id.to_s, newer_post.id.to_s, older_post.id.to_s
        ])
      end

      it 'フロントが期待する JSON 形状（id/title/body/youtubeUrl/userId/createdAt）で返す' do
        get "/api/v1/admin/users/#{target_user.id}/posts", headers: admin_auth_headers(admin)

        post_json = JSON.parse(response.body)['posts'].first
        expect(post_json.keys).to include('id', 'title', 'body', 'youtubeUrl', 'userId', 'createdAt')
        expect(post_json['id']).to eq(newest_post.id.to_s)
        expect(post_json['title']).to eq(newest_post.title)
        expect(post_json['body']).to eq(newest_post.body)
        expect(post_json['youtubeUrl']).to eq(newest_post.youtube_url)
        expect(post_json['userId']).to eq(target_user.id.to_s)
      end
    end

    context '動画投稿が0件の場合' do
      it '空配列を返す' do
        get "/api/v1/admin/users/#{target_user.id}/posts", headers: admin_auth_headers(admin)

        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)['posts']).to eq([])
      end
    end

    context '存在しないユーザーIDの場合' do
      it '404 を返す' do
        get '/api/v1/admin/users/0/posts', headers: admin_auth_headers(admin)

        expect(response).to have_http_status(:not_found)
      end
    end

    context '未認証の場合' do
      it '401 を返す' do
        get "/api/v1/admin/users/#{target_user.id}/posts"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context '管理者ではないユーザートークンの場合' do
      it '401 を返す（管理者専用エンドポイントのため）' do
        get "/api/v1/admin/users/#{target_user.id}/posts", headers: user_auth_headers(other_user)

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
