class CreateSuggestions < ActiveRecord::Migration[8.0]
  def change
    create_table :suggestions do |t|
      t.integer :family_id
      t.text :requests
      t.text :ai_raw_json
      t.string :chosen_option
      t.text :feedback

      t.timestamps
    end
  end
end
