# frozen_string_literal: true

Rails.application.routes.draw do
  root to: 'tasks#index'
  resources :tasks, except: %i[destroy] do
    delete :index, on: :collection, action: :delete
  end
end