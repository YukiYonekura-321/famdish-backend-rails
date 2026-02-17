class Family < ApplicationRecord
  has_many :users   # 家族の管理者
  has_many :members
  has_many :stocks, dependent: :destroy
  has_many :invitations, dependent: :destroy
  belongs_to :today_cook, class_name: "Member", optional: true
end
