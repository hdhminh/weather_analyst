class AddDeviseModulesToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :confirmation_token, :string
    add_column :users, :confirmed_at, :datetime
    add_column :users, :confirmation_sent_at, :datetime
    add_column :users, :unconfirmed_email, :string # Only if using reconfirmable

    add_column :users, :failed_attempts, :integer, default: 0, null: false # For :lockable
    add_column :users, :unlock_token, :string # For :lockable
    add_column :users, :locked_at, :datetime # For :lockable

    add_column :users, :last_request_at, :datetime # For :timeoutable
    add_column :users, :current_sign_in_at, :datetime # For :trackable
    add_column :users, :last_sign_in_at, :datetime # For :trackable
    add_column :users, :current_sign_in_ip, :string # For :trackable
    add_column :users, :last_sign_in_ip, :string # For :trackable
    
    add_column :users, :provider, :string # For :omniauthable
    add_column :users, :uid, :string # For :omniauthable

    add_index :users, :confirmation_token, unique: true
    add_index :users, :unlock_token, unique: true
    add_index :users, :uid
  end
end
