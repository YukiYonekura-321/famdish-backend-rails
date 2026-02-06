class ChangeFamilyIdTypeOnMembers < ActiveRecord::Migration[8.0]
  def change
    change_column :members, :family_id, :bigint
  end
end
