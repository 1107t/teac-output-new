# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Api::V1::Admin::Users', type: :request do
  let(:tenant_a) { create(:tenant, name: 'テナントA') }
  let(:tenant_b) { create(:tenant, name: 'テナントB') }
  let!(:admin_a) { create(:admin, tenant: tenant_a) }
  let!(:user_a)  { create(:user, tenant: tenant_a) }
  let!(:user_b)  { create(:user, tenant: tenant_b) }

  def auth_headers_for(admin)
    token = JwtHelper.encode(id: admin.id, role: 'admin')
    { 'Authorization' => "Bearer #{token}" }
  end

  describe 'GET /api/v1/admin/users' do
    it '自分のテナントのユーザーのみが一覧に含まれる' do
      get '/api/v1/admin/users', headers: auth_headers_for(admin_a)

      ids = JSON.parse(response.body)['users'].map { |u| u['id'] }
      expect(ids).to include(user_a.id.to_s)
      expect(ids).not_to include(user_b.id.to_s)
    end
  end

  describe 'GET /api/v1/admin/users/:id' do
    it '他テナントのユーザーIDを指定すると見つからない（404）' do
      get "/api/v1/admin/users/#{user_b.id}", headers: auth_headers_for(admin_a)

      expect(response).to have_http_status(:not_found)
    end

    it '自テナントのユーザーIDなら取得できる' do
      get "/api/v1/admin/users/#{user_a.id}", headers: auth_headers_for(admin_a)

      expect(response).to have_http_status(:ok)
    end
  end

  describe 'DELETE /api/v1/admin/users/:id' do
    it '他テナントのユーザーは削除できない（404で、実際に削除もされない）' do
      expect do
        delete "/api/v1/admin/users/#{user_b.id}", headers: auth_headers_for(admin_a)
      end.not_to change(User.unscoped, :count)

      expect(response).to have_http_status(:not_found)
    end
  end
end
