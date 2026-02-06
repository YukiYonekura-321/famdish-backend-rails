class ChangeFamilyIdNullOnUsers < ActiveRecord::Migration[8.0]
  def change
    change_column_null :users, :family_id, true
  end
end
