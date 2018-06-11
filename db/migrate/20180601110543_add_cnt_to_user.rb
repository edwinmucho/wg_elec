class AddCntToUser < ActiveRecord::Migration[5.1]
  def change
    add_column :users, :tdy_cnt, :integer
    add_column :users, :ttl_cnt, :integer
  end
end
