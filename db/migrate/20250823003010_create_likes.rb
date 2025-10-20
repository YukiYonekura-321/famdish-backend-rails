class CreateLikes < ActiveRecord::Migration[8.0]
  def change
    create_table :likes do |t|
      t.references :member, null: false, foreign_key: true
      t.string :name

      t.timestamps
    end
  end
end
