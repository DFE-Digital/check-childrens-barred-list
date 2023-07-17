Rails.application.routes.draw do
  root to: "pages#home"

  mount FeatureFlags::Engine => "/features"
end
