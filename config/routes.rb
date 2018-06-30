# frozen_string_literal: true

Rails.application.routes.draw do
  root to: 'tasks#index'
  # resources :tasks, except: %i[destroy] do
  resources :tasks  do
    delete :index, on: :collection, action: :delete
    resources :comments
  end
end