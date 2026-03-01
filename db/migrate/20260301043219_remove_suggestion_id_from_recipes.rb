class RemoveSuggestionIdFromRecipes < ActiveRecord::Migration[8.0]
  def change
    remove_foreign_key :recipes, :suggestions
    remove_column :recipes, :suggestion_id, :bigint
  end
end
