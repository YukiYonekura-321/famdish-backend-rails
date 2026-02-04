class Family < ApplicationRecord
  has_many :users   # 家族の管理者
  has_many :members
end
