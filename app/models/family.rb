class Family < ApplicationRecord
  belongs_to :user   # 家族の管理者
  has_many :members
end
