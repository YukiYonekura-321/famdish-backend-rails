require 'rails_helper'

RSpec.describe Good, type: :model do
  describe "バリデーション" do
    it { is_expected.to validate_presence_of(:user_id) }

    it "menu_id と suggestion_id の両方が空のとき無効" do
      good = build(:good, user_id: 1, menu_id: nil, suggestion_id: nil)
      expect(good).not_to be_valid
      expect(good.errors[:base]).to include("menu_id または suggestion_id が必要です")
    end

    it "menu_id があれば有効" do
      good = build(:good, user_id: 1, menu_id: 1)
      expect(good).to be_valid
    end

    it "suggestion_id があれば有効" do
      good = build(:good, user_id: 1, suggestion_id: 1)
      expect(good).to be_valid
    end
  end
end
