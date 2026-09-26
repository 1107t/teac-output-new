# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Api::V1::Auth::Admins', type: :request do
  let(:tenant_a) { create(:tenant, name: 'テナントA') }
  let(:tenant_b) { create(:tenant, name: 'テナントB') }

  describe 'GET /api/v1/admin/auth/me' do
    let!(:admin_a) { create(:admin, tenant: tenant_a) }
    let!(:admin_b) { create(:admin, tenant: tenant_b) }

    def token_for(admin)
      JwtHelper.encode(id: admin.id, role: 'admin')
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
  end
end
