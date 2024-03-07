FactoryBot.define do
  factory :role do
    sequence(:code) { |n| "TestCode-#{n}" }
    enabled { false }
    internal { false }
    trait :enabled do
      enabled { true }
    end
    trait :internal do
      internal { true }
    end
  end
end
