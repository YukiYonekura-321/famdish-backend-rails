class AddUserIdToMembers < ActiveRecord::Migration[8.0]
  def change
    add_reference :members, :user, null: false, foreign_key: true
  end
end
