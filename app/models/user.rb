class User < ApplicationRecord
  validates :firebase_uid, presence: true, uniqueness: true
end
