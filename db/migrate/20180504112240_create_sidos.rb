class CreateSidos < ActiveRecord::Migration[5.1]
  def change
    create_table :sidos do |t|
      t.string :wiwid
      t.string :wiwname
      t.string :findlist

      t.timestamps
    end
  end
end
