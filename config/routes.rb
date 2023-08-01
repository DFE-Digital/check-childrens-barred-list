Rails.application.routes.draw do
  root to: "searches#new"

  get "/search", to: "searches#new"
  get "/result", to: "searches#show"

  get "/sign-in", to: "sign_in#new"
  get "/sign-out", to: "sign_out#new"

  get "/auth/dfe/callback", to: "omniauth_callbacks#dfe"
  post "/auth/developer/callback" => "omniauth_callbacks#dfe_bypass"

  namespace :support_interface, path: "/support" do
    root to: redirect("/support/features")

    mount FeatureFlags::Engine => "/features"

    resources :uploads, only: %i[new create index]
  end
end
