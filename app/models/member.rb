class Member < ApplicationRecord
  has_many :likes, dependent: :destroy
  has_many :dislikes, dependent: :destroy

  accepts_nested_attributes_for :likes, allow_destroy: true
  accepts_nested_attributes_for :dislikes, allow_destroy: true
end
