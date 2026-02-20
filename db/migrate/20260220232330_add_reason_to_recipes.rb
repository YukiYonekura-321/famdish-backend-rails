class AddReasonToRecipes < ActiveRecord::Migration[8.0]
  def change
    add_column :recipes, :reason, :text
  end
end
