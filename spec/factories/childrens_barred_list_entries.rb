FactoryBot.define do
  factory :childrens_barred_list_entry do
    first_names { "John" }
    last_name { "Doe" }
    date_of_birth { 25.years.ago.to_date.to_fs(:db) }
    confirmed { true }
    confirmed_at { 1.day.ago }
    upload_file_hash { Digest::SHA256.hexdigest("test") }

    trait :unconfirmed do
      confirmed { false }
      confirmed_at { nil }
    end
  end
end
