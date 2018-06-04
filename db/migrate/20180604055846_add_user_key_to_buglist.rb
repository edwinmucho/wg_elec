class AddUserKeyToBuglist < ActiveRecord::Migration[5.1]
  def change
    add_column :buglists, :user_key, :string
  end
end
