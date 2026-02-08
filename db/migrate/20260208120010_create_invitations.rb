class CreateInvitations < ActiveRecord::Migration[8.0]
  def change
    create_table :invitations do |t|
      t.string :token, null: false
      t.references :family, null: false, foreign_key: true
      t.boolean :used, default: false, null: false
      t.datetime :expires_at, null: false

      t.timestamps
    end
    add_index :invitations, :token, unique: true
  end
end
