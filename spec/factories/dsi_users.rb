FactoryBot.define do
  factory :dsi_user do
    sequence :email do |n|
      "dsi-user-#{n}@example.com"
    end

    first_name { "Steven" }
    last_name { "Toast" }
    uid { "123" }
  end
end
