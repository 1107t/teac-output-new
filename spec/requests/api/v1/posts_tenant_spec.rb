# frozen_string_literal: true

require 'rails_helper'

# 動画（posts）がテナントごとに分離されていることを確認する
RSpec.describe 'Api::V1 posts のテナント分離', type: :request do
  def admin_auth_headers(admin)
    { 'Authorization' => "Bearer #{JwtHelper.encode(id: admin.id, role: 'admin', tenant_id: admin.tenant_id)}" }
  end

  def user_auth_headers(user)
    { 'Authorization' => "Bearer #{JwtHelper.encode(id: user.id, role: 'user', tenant_id: user.tenant_id)}" }
  end

  let(:tenant) { create(:tenant) }
  let(:other_tenant) { create(:tenant) }
  let(:admin) { create(:admin, tenant: tenant) }
  let(:user) { create(:user, tenant: tenant) }
  let(:other_user) { create(:user, tenant: other_tenant) }

  let!(:own_post) { create(:post, user: user, admin: nil) }
  let!(:other_tenant_post) { create(:post, user: other_user, admin: nil) }

  describe '作成時のテナント' do
    it '受講生の投稿は受講生のテナントになる' do
      expect(own_post.tenant).to eq(tenant)
      expect(other_tenant_post.tenant).to eq(other_tenant)
    end

    it '管理者の投稿は管理者のテナントになる' do
      post '/api/v1/admin/posts', params: { title: 't', body: 'b', youtube_url: 'https://www.youtube.com/watch?v=x' },
                                  headers: admin_auth_headers(admin)

      expect(response).to have_http_status(:created)
      expect(Post.unscoped.find(JSON.parse(response.body)['post']['id']).tenant).to eq(tenant)
    end
  end

  describe 'GET /api/v1/admin/posts' do
    it '自分のテナントの投稿だけを返す' do
      get '/api/v1/admin/posts', headers: admin_auth_headers(admin)

      expect(response).to have_http_status(:ok)
      ids = JSON.parse(response.body)['posts'].map { |p| p['id'] }
      expect(ids).to include(own_post.id.to_s)
      expect(ids).not_to include(other_tenant_post.id.to_s)
    end
  end

  describe 'GET /api/v1/admin/posts/:id' do
    it '他テナントの投稿は 404' do
      get "/api/v1/admin/posts/#{other_tenant_post.id}", headers: admin_auth_headers(admin)

      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'GET /api/v1/posts/:id' do
    it '他テナントの投稿は 404' do
      get "/api/v1/posts/#{other_tenant_post.id}", headers: user_auth_headers(user)

      expect(response).to have_http_status(:not_found)
    end

    it '自分のテナントの投稿は 200' do
      get "/api/v1/posts/#{own_post.id}", headers: user_auth_headers(user)

      expect(response).to have_http_status(:ok)
    end
  end
end
