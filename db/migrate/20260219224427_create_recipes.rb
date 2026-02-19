class CreateRecipes < ActiveRecord::Migration[8.0]
  def change
    create_table :recipes do |t|
      t.string :dish_name, null: false
      t.bigint :proposer
      t.integer :servings
      t.json :missing_ingredients
      t.integer :cooking_time
      t.json :steps

      t.timestamps
    end

    add_foreign_key :recipes, :members, column: :proposer
  end
end
