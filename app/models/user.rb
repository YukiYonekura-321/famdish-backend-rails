class User < ApplicationRecord
  validates :firebase_uid, presence: true, uniqueness: true
  belongs_to :family
  has_many :members, through: :family
end
