class RenameMenuToNameInMenus < ActiveRecord::Migration[8.0]
  def change
    rename_column :menus, :menu, :name
  end
end
