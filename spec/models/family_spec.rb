require 'rails_helper'

RSpec.describe Family, type: :model do
  describe "アソシエーション" do
    it { is_expected.to have_many(:users) }
    it { is_expected.to have_many(:members) }
    it { is_expected.to have_many(:stocks).dependent(:destroy) }
    it { is_expected.to have_many(:invitations).dependent(:destroy) }
    it { is_expected.to belong_to(:today_cook).class_name("Member").optional }
  end

  describe "ファクトリ" do
    it "有効なファクトリを持つ" do
      expect(build(:family)).to be_valid
    end
  end
end
