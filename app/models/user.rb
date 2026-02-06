class User < ApplicationRecord
  validates :firebase_uid, presence: true, uniqueness: true
  # ユーザー登録（まだ家族なし）
  # 後から家族を作る or 招待で入る
  belongs_to :family, optional: true
  has_one :members, dependent: :destory
end
