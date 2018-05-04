class CreateGusiguns < ActiveRecord::Migration[5.1]
  def change
    create_table :gusiguns do |t|
      t.references :sido, foreign_key: true
      t.string :wiwid
      t.string :wiwtypecode
      t.string :towncode
      t.string :townname
      t.string :guname

      t.timestamps
    end
  end
end
