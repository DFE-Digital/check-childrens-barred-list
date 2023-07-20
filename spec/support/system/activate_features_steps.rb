module ActivateFeaturesSteps
  def given_the_service_is_open
    FeatureFlags::FeatureFlag.activate(:service_open)
  end
end
