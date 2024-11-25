class User < ApplicationRecord
  # This class represents the User model, which uses Devise for authentication and adds additional functionality.
  
  # Devise modules for user authentication. These include:
  # - `database_authenticatable`: Handles storing encrypted passwords and validating users while signing in.
  # - `registerable`: Allows users to sign up, edit, and delete their accounts.
  # - `recoverable`: Provides password recovery functionality.
  # - `rememberable`: Manages generating and clearing remember-me tokens for persistent sessions.
  # - `validatable`: Validates the email and password.
  # - `lockable`: Locks accounts after a certain number of failed attempts.
  # - `timeoutable`: Expires user sessions after a period of inactivity.
  # - `trackable`: Tracks sign-in counts, timestamps, and IP addresses.
  # - `omniauthable`: Allows integration with third-party login providers like Google, GitHub, or Facebook.
  # `authentication_keys: [:login]` allows login using either username or email.
  devise :database_authenticatable, :registerable, :recoverable, 
         :rememberable, :validatable, :lockable, 
         :timeoutable, :trackable, :omniauthable, omniauth_providers: [:google_oauth2, :github, :facebook],
         authentication_keys: [:login]

  # Ensures that the `username` field is present and unique.
  validates :username, presence: true, uniqueness: { case_sensitive: false }
  validates_format_of :username, with: /^[a-zA-Z0-9_\.]*$/, :multiline => true
  validate :validate_username

  def validate_username
    if User.where(email: username).exists?
      errors.add(:username, :invalid)
    end
  end

  # Custom login attribute writer to handle both username and email logins.
  attr_writer :login
  
  # Custom method to determine the login value. 
  # It first checks for `@login`, then `username`, and finally falls back to `email`.
  def login
    @login || username || email
  end

  # Custom method to allow Devise to authenticate users by either username or email.
  def self.find_for_database_authentication(warden_conditions)
    conditions = warden_conditions.dup
    if (login = conditions.delete(:login))
      where(conditions.to_h).where(["lower(username) = :value OR lower(email) = :value", { :value => login.downcase }]).first
    elsif conditions.has_key?(:username) || conditions.has_key?(:email)
      where(conditions.to_h).first
    end
  end

  # Method to handle OmniAuth logins (e.g., Google, GitHub, Facebook).
  def self.from_omniauth(access_token)
    # Extract user information from the OmniAuth access token.
    data = access_token.info
    provider = access_token.provider # Identify the provider (e.g., Google, GitHub).
    
    # Attempt to find a user with the same email in the database.
    user = User.where(email: data['email']).first
  
    # If no user exists with the provided email, create a new one.
    unless user
        user = User.create( 
            # Uncomment the line below if your User model includes a `name` field.
            # name: data['name'],
            email: data['email'], # Set the user's email from OmniAuth data.
            password: Devise.friendly_token[0,20], # Generate a random password for the new user.
            provider: provider, # Save the OmniAuth provider (e.g., Google).
            uid: access_token.uid,  # Save the unique identifier provided by the OmniAuth provider.
            username: data['name'] || data['email'].split('@').first
        )
    end

    # If the user's existing provider or UID doesn't match the current login provider or UID, update them.
    if user.provider != provider || user.uid != access_token.uid
      user.update(provider: provider, uid: access_token.uid)
    end
    
    user # Return the authenticated or newly created user.
  end
end
