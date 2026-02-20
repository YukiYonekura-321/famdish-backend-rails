class AddSuggestionIdToRecipes < ActiveRecord::Migration[8.0]
  def change
    add_column :recipes, :suggestion_id, :bigint
    add_foreign_key :recipes, :suggestions
  end
end
