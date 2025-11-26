class ChangeRequestsToJsonInSuggestions < ActiveRecord::Migration[8.0]
  def change
    change_column :suggestions, :requests, :json, using: 'requests::json'
  end
end
