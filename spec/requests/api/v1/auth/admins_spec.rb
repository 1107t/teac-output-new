# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Api::V1::Auth::Admins', type: :request do
  let(:tenant_a) { create(:tenant, name: 'テナントA') }
  let(:tenant_b) { create(:tenant, name: 'テナントB') }

  describe 'POST /api/v1/admin/auth/login' do
    let!(:admin) { create(:admin, email: 'admin@example.com', password: 'password', tenant: tenant_a) }

    it 'トークンに所属テナントの tenant_id が含まれる' do
      post '/api/v1/admin/auth/login', params: { email: admin.email, password: 'password' }

      expect(response).to have_http_status(:ok)
      payload = JwtHelper.decode(JSON.parse(response.body)['token'])
      expect(payload['tenant_id']).to eq(tenant_a.id)
    end
  end

  describe 'GET /api/v1/admin/auth/me' do
    let!(:admin_a) { create(:admin, tenant: tenant_a) }
    let!(:admin_b) { create(:admin, tenant: tenant_b) }

    def token_for(admin)
      JwtHelper.encode(id: admin.id, role: 'admin', tenant_id: admin.tenant_id)
    end

    it 'リクエストパラメータではなく、認証済み管理者自身の tenant_id を返す' do
      get '/api/v1/admin/auth/me', headers: { 'Authorization' => "Bearer #{token_for(admin_a)}" }

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)['admin']['tenantId']).to eq(tenant_a.id.to_s)
    end

    it '管理者が異なればテナントの判定結果も異なる' do
      get '/api/v1/admin/auth/me', headers: { 'Authorization' => "Bearer #{token_for(admin_b)}" }

      expect(JSON.parse(response.body)['admin']['tenantId']).to eq(tenant_b.id.to_s)
    end

    it 'トークンの tenant_id が管理者の所属テナントと異なる場合は 401 を返す' do
      token = JwtHelper.encode(id: admin_a.id, role: 'admin', tenant_id: tenant_b.id)
      get '/api/v1/admin/auth/me', headers: { 'Authorization' => "Bearer #{token}" }

      expect(response).to have_http_status(:unauthorized)
    end

    it 'トークンに tenant_id が含まれない場合は 401 を返す' do
      token = JwtHelper.encode(id: admin_a.id, role: 'admin')
      get '/api/v1/admin/auth/me', headers: { 'Authorization' => "Bearer #{token}" }

      expect(response).to have_http_status(:unauthorized)
    end
  end
end
