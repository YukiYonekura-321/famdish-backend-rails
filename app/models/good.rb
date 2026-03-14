class Good < ApplicationRecord
  validates :user_id, presence: true
  # menu_id または suggestion_id のどちらかが必要
  validate :menu_or_suggestion_present

  private

  def menu_or_suggestion_present
    if menu_id.blank? && suggestion_id.blank?
      errors.add(:base, "menu_id または suggestion_id が必要です")
    end
  end
end
