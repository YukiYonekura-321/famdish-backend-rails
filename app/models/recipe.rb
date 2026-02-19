class Recipe < ApplicationRecord
  belongs_to :member, foreign_key: :proposer, optional: true

  validates :dish_name, presence: true
end
