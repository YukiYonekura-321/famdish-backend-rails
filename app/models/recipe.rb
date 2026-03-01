class Recipe < ApplicationRecord
  belongs_to :member, foreign_key: :proposer, optional: true
  belongs_to :suggestion, optional: true
  belongs_to :family, optional: true

  validates :dish_name, presence: true
end
