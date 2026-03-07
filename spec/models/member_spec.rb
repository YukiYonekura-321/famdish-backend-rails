require 'rails_helper'

RSpec.describe Member, type: :model do
  describe "アソシエーション" do
    it { is_expected.to belong_to(:family) }
    it { is_expected.to belong_to(:user).optional }
    it { is_expected.to have_many(:likes).dependent(:destroy) }
    it { is_expected.to have_many(:dislikes).dependent(:destroy) }
    it { is_expected.to have_many(:menus).dependent(:destroy) }
  end

  describe "nested attributes" do
    it { is_expected.to accept_nested_attributes_for(:likes).allow_destroy(true) }
    it { is_expected.to accept_nested_attributes_for(:dislikes).allow_destroy(true) }
    it { is_expected.to accept_nested_attributes_for(:menus).allow_destroy(true) }
  end

  describe "ファクトリ" do
    it "有効なファクトリを持つ" do
      expect(build(:member)).to be_valid
    end
  end
end
