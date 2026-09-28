# frozen_string_literal: true

FactoryBot.define do
  factory :manager do
    sequence(:email) { |n| "manager#{n}@example.com" }
    name { 'マネージャー' }
    password { 'password' }
    password_confirmation { 'password' }
    confirmed_at { Time.current }
  end
end
