# frozen_string_literal: true

Rails.application.routes.draw do
  resources :users

  scope constraints: {id: /.+/} do
    resources :ht_users
  end

  scope format: false, constraints: {id: /.+/} do
    resources :ht_approval_requests
  end

  root "ht_users#index"

  scope format: false, constraints: {id: /.+/} do
    resources :ht_institutions
  end

  scope format: false, constraints: {id: /.+/} do
    resources :ht_contacts
  end

  scope format: false, constraints: {id: /.+/} do
    resources :ht_contact_types
  end

  get "/ht_downloads/:role", to: "ht_downloads#index", as: :ht_downloads

  scope constraints: {id: /.+/} do
    resources :ht_logs
  end

  scope format: false, constraints: {id: /.+/} do
    resources :ht_registrations do
      member do
        get "preview"
        post "mail"
        post "finish"
        post "approve"
      end
    end
  end

  get "/login", to: "session#new", as: "login"
  post "/login", to: "session#create", as: "login_as"
  unless Rails.env.production?
    match "/logout", to: "session#destroy", as: "logout", via: [:get, :post]
  end

  get "/approve/:token", to: "approval#new", as: :approve

  get "/submit_registration/:token", to: "submit_registration#new", as: :submit_registration

  unless Rails.env.production?
    get "Shibboleth.sso/Login", controller: :fake_shib, as: :fake_shib, action: :new
  end
end
