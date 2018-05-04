class CreateEmds < ActiveRecord::Migration[5.1]
  def change
    create_table :emds do |t|
      t.references :gusigun, foreign_key: true
      t.string :towncode
      t.string :emdcode
      t.string :emdname
      t.string :findlist

      t.timestamps
    end
  end
end
