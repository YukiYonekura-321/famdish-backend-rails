class AddProposerToSuggestions < ActiveRecord::Migration[8.0]
  def change
    add_column :suggestions, :proposer, :bigint, null: false
    add_foreign_key :suggestions, :members, column: :proposer
  end
end
