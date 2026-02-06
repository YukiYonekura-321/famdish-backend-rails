class ChangeFamilyIdNullOnMembers < ActiveRecord::Migration[8.0]
  def change
    change_column_null :members, :family_id, false
  end
end
