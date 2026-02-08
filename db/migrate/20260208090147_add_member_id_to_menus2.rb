class AddMemberIdToMenus2 < ActiveRecord::Migration[8.0]
  def change
    add_reference :menus, :member, null: false, foreign_key: true
  end
end
