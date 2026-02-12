class Good < ApplicationRecord
  validates :user_id, presence: true
  validates :menu_id, presence: true
end
