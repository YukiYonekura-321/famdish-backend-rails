class CreateTrialUsages < ActiveRecord::Migration[8.0]
  def change
    create_table :trial_usages do |t|
      t.string :firebase_uid, null: false
      t.integer :usage_count, null: false, default: 0

      t.timestamps
    end

    add_index :trial_usages, :firebase_uid, unique: true
  end
end
