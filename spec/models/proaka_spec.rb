require 'rails_helper'

RSpec.describe Proaka, type: :model do
  it 'is valid with a name' do
    expect(build(:proaka, name: 'プロアカ')).to be_valid
  end

  it 'is invalid without a name' do
    proaka = build(:proaka, name: nil)
    proaka.valid?
    expect(proaka.errors[:name]).to include('を入力してください')
  end
end
