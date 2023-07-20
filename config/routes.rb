Rails.application.routes.draw do
  root to: "searches#new"

  get "/search", to: "searches#new"
  get "/result", to: "searches#show"

  mount FeatureFlags::Engine => "/features"
end
