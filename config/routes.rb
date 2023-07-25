Rails.application.routes.draw do
  root to: "searches#new"

  get "/search", to: "searches#new"
  get "/result", to: "searches#show"

  namespace :support_interface, path: "/support" do
    root to: redirect("/support/features")

    mount FeatureFlags::Engine => "/features"

    resources :uploads, only: %i[new create index]
  end
end
