require 'rails_helper'

RSpec.describe Suggestion, type: :model do
  describe "アソシエーション" do
    it { is_expected.to belong_to(:family).optional }
    it { is_expected.to have_many(:recipes).dependent(:nullify) }
  end

  describe "バリデーション" do
    it { is_expected.to validate_inclusion_of(:status).in_array(%w[pending processing completed failed]) }
  end

  describe "ステータスメソッド" do
    let(:family) { create(:family) }
    let(:member) { create(:member, family: family) }

    it "#completed? が正しく動作する" do
      suggestion = build(:suggestion, family: family, proposer: member.id, status: "completed",
                         ai_raw_json: '{}')
      expect(suggestion.completed?).to be true
      expect(suggestion.failed?).to be false
    end

    it "#failed? が正しく動作する" do
      suggestion = build(:suggestion, family: family, proposer: member.id, status: "failed")
      expect(suggestion.failed?).to be true
    end

    it "#pending? が正しく動作する" do
      suggestion = build(:suggestion, family: family, proposer: member.id, status: "pending")
      expect(suggestion.pending?).to be true
    end
  end

  describe "ファクトリ" do
    it "有効なファクトリを持つ" do
      family = create(:family)
      member = create(:member, family: family)
      expect(build(:suggestion, family: family, proposer: member.id)).to be_valid
    end
  end
end
