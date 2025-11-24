class AddFamilyIdToMembers < ActiveRecord::Migration[8.0]
  def change
    add_column :members, :family_id, :integer
  end
end
