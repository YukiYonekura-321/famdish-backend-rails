class CreateStocks < ActiveRecord::Migration[8.0]
  def change
    create_table :stocks do |t|
      t.bigint :family_id, null: false
      t.string :name, null: false
      t.decimal :quantity
      t.string :unit

      t.timestamps
    end

    add_index :stocks, :family_id
    add_foreign_key :stocks, :families
  end
end
