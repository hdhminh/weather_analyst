class AddTimeoutableToDevise < ActiveRecord::Migration[8.0]
  def change
    change_table :users, bulk: true do |t|
      t.datetime :last_request_at
    end
  end
end
