class RemoveSuggestionIdFromGoods < ActiveRecord::Migration[8.0]
  def change
    remove_foreign_key :goods, column: :suggestion_id
  end
end
