# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Api::V1::Manager::Tenants', type: :request do
  let!(:proaka) { create(:proaka, name: 'プロアカ1') }
  let(:manager) { create(:manager) }

  def auth_headers_for(manager)
    { 'Authorization' => "Bearer #{JwtHelper.encode(id: manager.id, role: 'manager')}" }
  end

  describe 'POST /api/v1/manager/tenants' do
    let(:valid_params) do
      {
        name: 'A社',
        admin_name: 'A社管理者',
        admin_email: 'a-admin@example.com',
        admin_password: 'password',
        admin_password_confirmation: 'password'
      }
    end

    context '有効なテナント名と管理者情報を指定した場合' do
      it 'テナントとそのテナントの管理者を作成する' do
        expect do
          post '/api/v1/manager/tenants', params: valid_params, headers: auth_headers_for(manager)
        end.to change(Tenant, :count).by(1).and change(Admin.unscoped, :count).by(1)

        expect(response).to have_http_status(:created)
        tenant = Tenant.last
        admin = Admin.unscoped.find_by(email: 'a-admin@example.com')
        expect(tenant.name).to eq('A社')
        expect(admin.tenant_id).to eq(tenant.id)
        expect(admin.name).to eq('A社管理者')
      end

      it '作成した管理者はメールアドレスとパスワードでログインできる' do
        post '/api/v1/manager/tenants', params: valid_params, headers: auth_headers_for(manager)

        post '/api/v1/admin/auth/login', params: { email: 'a-admin@example.com', password: 'password' }

        expect(response).to have_http_status(:ok)
        payload = JwtHelper.decode(JSON.parse(response.body)['token'])
        expect(payload['tenant_id']).to eq(Tenant.last.id)
      end

      it 'レスポンスにテナントと管理者の情報を含み、パスワードは含まない' do
        post '/api/v1/manager/tenants', params: valid_params, headers: auth_headers_for(manager)

        body = JSON.parse(response.body)
        expect(body['tenant']['name']).to eq('A社')
        expect(body['admin']['email']).to eq('a-admin@example.com')
        expect(response.body).not_to include('password')
      end
    end

    context '管理者のメールアドレスを指定しない場合' do
      it '422 を返し、テナントも管理者も作成しない' do
        expect do
          post '/api/v1/manager/tenants', params: valid_params.except(:admin_email), headers: auth_headers_for(manager)
        end.to change(Tenant, :count).by(0).and change(Admin.unscoped, :count).by(0)

        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)['errors']).to be_present
      end
    end

    context '管理者のパスワードを指定しない場合' do
      it '422 を返し、テナントも管理者も作成しない' do
        expect do
          post '/api/v1/manager/tenants', params: valid_params.except(:admin_password, :admin_password_confirmation),
                                          headers: auth_headers_for(manager)
        end.to change(Tenant, :count).by(0).and change(Admin.unscoped, :count).by(0)

        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context 'パスワード確認が一致しない場合' do
      it '422 を返し、テナントも管理者も作成しない' do
        expect do
          post '/api/v1/manager/tenants', params: valid_params.merge(admin_password_confirmation: 'different'),
                                          headers: auth_headers_for(manager)
        end.to change(Tenant, :count).by(0).and change(Admin.unscoped, :count).by(0)

        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context '管理者名を指定しない場合' do
      it '422 を返し、テナントも管理者も作成しない' do
        expect do
          post '/api/v1/manager/tenants', params: valid_params.except(:admin_name), headers: auth_headers_for(manager)
        end.to change(Tenant, :count).by(0).and change(Admin.unscoped, :count).by(0)

        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context '既に使われている管理者メールアドレスを指定した場合' do
      before { create(:admin, email: 'a-admin@example.com') }

      it '422 を返し、テナントを作成しない' do
        expect do
          post '/api/v1/manager/tenants', params: valid_params, headers: auth_headers_for(manager)
        end.not_to change(Tenant, :count)

        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'メールアドレスが使われていることをエラーで返す' do
        post '/api/v1/manager/tenants', params: valid_params, headers: auth_headers_for(manager)

        errors = JSON.parse(response.body)['errors']
        expect(errors).to include(a_string_including('すでに存在します'))
        expect(errors).not_to include(a_string_including('不正な値です'))
      end
    end

    context 'テナント名が空の場合' do
      it '422 を返し、管理者を作成しない' do
        expect do
          post '/api/v1/manager/tenants', params: valid_params.merge(name: ''), headers: auth_headers_for(manager)
        end.not_to change(Admin.unscoped, :count)

        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context 'マネージャーとして認証していない場合' do
      it '401 を返す' do
        post '/api/v1/manager/tenants', params: valid_params

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
