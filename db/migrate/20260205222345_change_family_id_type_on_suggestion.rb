class ChangeFamilyIdTypeOnSuggestion < ActiveRecord::Migration[8.0]
  def change
    change_column :suggestions, :family_id, :bigint
  end
end
