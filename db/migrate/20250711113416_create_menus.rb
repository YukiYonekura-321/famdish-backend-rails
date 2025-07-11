class CreateMenus < ActiveRecord::Migration[8.0]
  def change
    create_table :menus do |t|
      t.string :menu
      t.string :favorite

      t.timestamps
    end
  end
end
