# frozen_string_literal: true
namespace :db do
  desc "Seeds role codes from environment into the database"
  task seed_role_codes: :environment do
    if ENV["DFE_SIGN_IN_API_INTERNAL_USER_ROLE_CODE"]
      Role.find_or_create_by!(code: ENV["DFE_SIGN_IN_API_INTERNAL_USER_ROLE_CODE"]) do |role|
        role.enabled = true
        role.internal = true
      end
    end

    if ENV["DFE_SIGN_IN_API_ROLE_CODES"]
      ENV["DFE_SIGN_IN_API_ROLE_CODES"].split(",").each do |role_code|
        Role.find_or_create_by!(code: role_code) do |role|
          role.enabled = true
        end
      end
    end

    roles = Role.all

    if roles.any?
      puts "Roles in the database:"
      Role.all.find_each do |role|
        puts "Role: #{role.code} enabled: #{role.enabled} internal: #{role.internal}"
      end
    end
  end
end
