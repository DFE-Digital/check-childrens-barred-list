module ActivateFeaturesSteps
  def given_the_service_is_open
    FeatureFlags::FeatureFlag.activate(:service_open)
  end

  def and_the_downtime_banner_is_active
    FeatureFlags::FeatureFlag.activate(:downtime_banner)
  end
end
