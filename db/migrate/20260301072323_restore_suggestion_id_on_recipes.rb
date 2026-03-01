class RestoreSuggestionIdOnRecipes < ActiveRecord::Migration[8.0]
  def change
    add_reference :recipes, :suggestion, null: true, foreign_key: true
  end
end
