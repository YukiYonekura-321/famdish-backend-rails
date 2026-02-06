class AddForeignKeyToMembersFamily < ActiveRecord::Migration[8.0]
  def change
    add_foreign_key :members, :families
    add_index :members, :family_id
  end
end
