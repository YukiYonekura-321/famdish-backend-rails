class AddFamilyIdToRecipes < ActiveRecord::Migration[8.0]
  def change
    add_column :recipes, :family_id, :bigint
    add_foreign_key :recipes, :families
  end
end
