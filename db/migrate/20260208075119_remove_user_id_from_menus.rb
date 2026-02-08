class RemoveUserIdFromMenus < ActiveRecord::Migration[8.0]
  def change
    remove_foreign_key :menus, :users
    remove_column :menus, :user_id, :bigint
  end
end
