class RemoveFavoriteFromMenus < ActiveRecord::Migration[8.0]
  def change
    remove_column :menus, :favorite, :string
  end
end
