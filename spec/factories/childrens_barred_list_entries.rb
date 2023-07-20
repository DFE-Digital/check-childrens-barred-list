FactoryBot.define do
  factory :childrens_barred_list_entry do
    first_names { "John" }
    last_name { "Doe" }
    date_of_birth { 25.years.ago }
  end
end
