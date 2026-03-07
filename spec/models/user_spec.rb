require 'rails_helper'

RSpec.describe User, type: :model do
  describe "バリデーション" do
    it { is_expected.to validate_presence_of(:firebase_uid) }
    it { is_expected.to validate_uniqueness_of(:firebase_uid) }
  end

  describe "アソシエーション" do
    it { is_expected.to belong_to(:family).optional }
    it { is_expected.to have_one(:member).dependent(:destroy) }
  end

  describe "ファクトリ" do
    it "有効なファクトリを持つ" do
      expect(build(:user)).to be_valid
    end
  end
end
