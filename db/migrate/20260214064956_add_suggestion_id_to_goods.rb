class AddSuggestionIdToGoods < ActiveRecord::Migration[8.0]
  def change
    add_column :goods, :suggestion_id, :bigint
    add_foreign_key :goods, :suggestions, column: :suggestion_id
    # menu_id の NOT NULL 制約を外す（suggestion_id のみの場合もあるため）
    change_column_null :goods, :menu_id, true
  end
end
