class DsiUser < ApplicationRecord
  has_many :dsi_user_sessions, dependent: :destroy

  def self.create_or_update_from_dsi(dsi_payload, role = nil)
    dsi_user = find_or_initialize_by(email: dsi_payload.info.fetch(:email))

    dsi_user.update!(
      first_name: dsi_payload.info.first_name,
      last_name: dsi_payload.info.last_name,
      uid: dsi_payload.uid
    )

    if role.present?
      dsi_user.dsi_user_sessions.create!(
        role_id: role["id"],
        role_code: role["code"],
        organisation_id: dsi_payload.extra.raw_info.organisation.id,
        organisation_name: dsi_payload.extra.raw_info.organisation.name,
      )
    end

    dsi_user
  end
end
