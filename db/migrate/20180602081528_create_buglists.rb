class CreateBuglists < ActiveRecord::Migration[5.1]
  def change
    create_table :buglists do |t|
      t.string :err_msg
      t.string :mstep
      t.string :fstep
      t.string :user_msg
      
      t.timestamps
    end
  end
end
