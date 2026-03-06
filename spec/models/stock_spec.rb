require 'rails_helper'

RSpec.describe Stock, type: :model do
  describe "バリデーション" do
    it { is_expected.to validate_presence_of(:name) }
  end

  describe "アソシエーション" do
    it { is_expected.to belong_to(:family) }
  end

  describe "ファクトリ" do
    it "有効なファクトリを持つ" do
      expect(build(:stock)).to be_valid
    end
  end
end
