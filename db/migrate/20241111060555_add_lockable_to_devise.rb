class AddLockableToDevise < ActiveRecord::Migration[8.0]
  def change
    change_table :users, bulk: true do |t|
      t.integer  :failed_attempts, default: 0, null: false # Only if lock strategy is :failed_attempts
      t.string   :unlock_token # Only if unlock strategy is :email or :both
      t.datetime :locked_at
    end
    add_index :users, :unlock_token, unique: true
  end
end
