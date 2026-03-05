require 'rails_helper'

RSpec.describe Recipe, type: :model do
  describe "バリデーション" do
    it { is_expected.to validate_presence_of(:dish_name) }
  end

  describe "アソシエーション" do
    it { is_expected.to belong_to(:member).with_foreign_key(:proposer).optional }
    it { is_expected.to belong_to(:suggestion).optional }
    it { is_expected.to belong_to(:family).optional }
  end

  describe "ファクトリ" do
    it "有効なファクトリを持つ" do
      expect(build(:recipe)).to be_valid
    end
  end
end
