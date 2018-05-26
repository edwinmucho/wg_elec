class CreateUsers < ActiveRecord::Migration[5.1]
  def change
    create_table :users do |t|
      t.integer :chat_room
      t.string :user_key
      
      t.string :sido
      t.string :sigun
      t.string :gu
      t.string :emd
      
      t.string :sido_code
      t.string :gusigun_code
      t.string :emd_code

      t.string :url
      t.timestamps
    end
  end
end
