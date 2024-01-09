Rails.application.routes.draw do
  root to: "searches#new"

  get "/search", to: "searches#new"
  get "/result", to: "searches#show"

  get "/sign-in", to: "sign_in#new"
  get "/sign-out", to: "sign_out#new"
  get "/auth/dfe/sign-out", to: "sign_out#new", as: :dsi_sign_out

  get "/auth/dfe/callback", to: "omniauth_callbacks#dfe"
  post "/auth/developer/callback", to: "omniauth_callbacks#dfe_bypass"

  scope "/feedback" do
    get "/", to: "feedbacks#new", as: :feedbacks
    post "/", to: "feedbacks#create"
    get "/success", to: "feedbacks#success"
  end

  get "/accessibility", to: "static#accessibility"
  get "/cookies", to: "static#cookies"

  get '/401', to: 'errors#not_authorised', as: :not_authorised
  get '/422', to: 'errors#unprocessable_entity'
  get '/404', to: 'errors#not_found'
  get '/500', to: 'errors#internal_server_error'

  namespace :support_interface, path: "/support" do
    root to: redirect("/support/features")

    mount FeatureFlags::Engine => "/features"

    resources :uploads, only: %i[new create]
    get "/uploads/preview", to: "uploads#preview", as: :upload_preview
    post "/uploads/confirm", to: "uploads#confirm", as: :upload_confirm
    post "/uploads/cancel", to: "uploads#cancel", as: :upload_cancel
    get "/uploads/success", to: "uploads#success", as: :upload_success
  end
end
