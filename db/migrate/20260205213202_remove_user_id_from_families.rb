class RemoveUserIdFromFamilies < ActiveRecord::Migration[8.0]
  def change
    remove_foreign_key :families, :users
    remove_column :families, :user_id, :bigint
  end
end
