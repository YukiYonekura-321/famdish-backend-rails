class CreateGoods < ActiveRecord::Migration[8.0]
  def change
    create_table :goods do |t|
      t.integer :user_id
      t.integer :menu_id

      t.timestamps
    end
  end
end
