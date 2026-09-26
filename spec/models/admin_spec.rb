require 'rails_helper'

RSpec.describe Admin, type: :model do
  let(:tenant) { create(:tenant) }
  let(:proaka) { create(:proaka) }

  it 'is valid with a tenant and a proaka' do
    admin = build(:admin, tenant: tenant, proaka: proaka)
    expect(admin).to be_valid
  end

  it 'is invalid without a tenant' do
    admin = build(:admin, tenant: nil, proaka: proaka)
    admin.valid?
    expect(admin.errors[:tenant]).to include('を入力してください')
  end

  it 'is invalid without a proaka' do
    admin = build(:admin, tenant: tenant, proaka: nil)
    admin.valid?
    expect(admin.errors[:proaka]).to include('を入力してください')
  end
end
