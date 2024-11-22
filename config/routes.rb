Rails.application.routes.draw do
  # Define a route for the "pages#index" action.
  # This is accessed via a GET request to "pages/index".
  get "pages/index"

  # Set up routes for Devise's user authentication system.
  # The `controllers` option allows you to customize the controllers for specific Devise actions.
  devise_for :users, controllers: { 
    registrations: "users/registrations",     # Overrides default registration-related actions.
    sessions: "users/sessions",               # Overrides default session-related actions (e.g., login/logout).
    passwords: "users/passwords",             # Overrides actions for password reset and recovery.
    confirmations: "users/confirmations",     # Overrides actions for email confirmation.
    unlocks: "users/unlocks",                 # Overrides actions to unlock a locked account.
    omniauth_callbacks: "users/omniauth_callbacks" # Handles callbacks for OmniAuth (e.g., Google, Facebook).
  }

  # Devise-specific routes
  # Defines a custom route to destroy the session (logout) for users.
  # This allows users to sign out using a GET request to '/users/sign_out'.
  devise_scope :user do  
    get '/users/sign_out' => 'devise/sessions#destroy'    
  end

  # Health check route for the application.
  # Accessed via GET request to "/up".
  # It is used by uptime monitors or load balancers to verify if the app is running correctly.
  # Returns 200 if the app has booted successfully; otherwise, it returns 500.
  get "up" => "rails/health#show", as: :rails_health_check

  # Custom route to toggle a unit (specific action defined in PagesController).
  # Accessed via GET request to "/toggle_unit".
  # The `as: :toggle_unit` creates a URL helper `toggle_unit_path` for easier usage in views and controllers.
  get 'toggle_unit', to: 'pages#toggle_unit', as: :toggle_unit

  # Uncommented lines for dynamic Progressive Web App (PWA) file generation.
  # These routes would render dynamic PWA files from views located at `app/views/pwa/*`.
  # Remember to link these files (e.g., manifest) in the HTML head if uncommented.
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Root route: Defines the homepage of the application.
  # Accessed via GET request to "/".
  # This maps to the "index" action in the PagesController.
  root "pages#index"
end