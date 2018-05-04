class CreateUsers < ActiveRecord::Migration[5.1]
  def change
    create_table :users do |t|
      t.string :chat_room
      t.string :user_key

      t.timestamps
    end
  end
end
