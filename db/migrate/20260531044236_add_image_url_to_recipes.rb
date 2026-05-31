class AddImageUrlToRecipes < ActiveRecord::Migration[8.0]
  def change
    add_column :recipes, :image_url, :string
  end
end
