class AddUserIdToMenus < ActiveRecord::Migration[8.0]
  def change
    add_reference :menus, :user, null: false, foreign_key: true
  end
end
