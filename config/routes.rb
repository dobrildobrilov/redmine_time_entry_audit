Rails.application.routes.draw do
  # Unscoped
  resources :time_entry_audits, only: [:index] do
    collection { get :counts }
  end
  # Project-scoped (menu)
  get '/projects/:id/time_entry_audits', to: 'time_entry_audits#index', as: 'project_time_entry_audits'
end
