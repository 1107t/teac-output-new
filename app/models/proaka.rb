class Proaka < ApplicationRecord
  has_many :users, foreign_key: 'プロアカ_id', dependent: :restrict_with_error
  has_many :admins, foreign_key: 'プロアカ_id', dependent: :restrict_with_error

  validates :name, presence: true, length: { in: 1..20 }
end
