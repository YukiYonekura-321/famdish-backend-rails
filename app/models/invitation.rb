class Invitation < ApplicationRecord
  belongs_to :family

  validates :token, presence: true, uniqueness: true
  validates :expires_at, presence: true

  before_validation :generate_token, on: :create

  # 有効かどうか（未使用 & 期限内）
  def valid_invitation?
    !used? && expires_at > Time.current
  end

  # トークンを使用済みにする
  def mark_as_used!
    update!(used: true)
  end

  private

  def generate_token
    self.token ||= SecureRandom.urlsafe_base64(32)
  end
end
