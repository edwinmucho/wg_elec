class CreateJdcheers < ActiveRecord::Migration[5.1]
  def change
    create_table :jdcheers do |t|
      t.references :gusigun, foreign_key: true
      t.string :gsg_code
      t.string :jdname
      t.string :ele_code
      t.string :hubo
      t.integer :cheerup

      t.timestamps
    end
  end
end
