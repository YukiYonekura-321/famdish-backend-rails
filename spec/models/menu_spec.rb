require 'rails_helper'

RSpec.describe Menu, type: :model do
  describe "アソシエーション" do
    it { is_expected.to belong_to(:member) }
  end

  describe "ファクトリ" do
    it "有効なファクトリを持つ" do
      expect(build(:menu)).to be_valid
    end
  end
end
