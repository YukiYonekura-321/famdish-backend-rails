class AddTodayCookIdToFamilies < ActiveRecord::Migration[8.0]
  def change
    add_column :families, :today_cook_id, :bigint
    add_foreign_key :families, :members, column: :today_cook_id
  end
end
