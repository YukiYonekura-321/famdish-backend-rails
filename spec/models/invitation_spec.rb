require 'rails_helper'

RSpec.describe Invitation, type: :model do
  describe "バリデーション" do
    it { is_expected.to validate_presence_of(:expires_at) }

    it "token のユニーク制約" do
      family = create(:family)
      inv1 = create(:invitation, family: family)
      inv2 = build(:invitation, family: family, token: inv1.token)
      expect(inv2).not_to be_valid
    end
  end

  describe "アソシエーション" do
    it { is_expected.to belong_to(:family) }
  end

  describe "#generate_token" do
    it "作成時に自動でトークンを生成する" do
      invitation = create(:invitation)
      expect(invitation.token).to be_present
    end
  end

  describe "#valid_invitation?" do
    let(:family) { create(:family) }

    it "未使用かつ期限内なら true" do
      invitation = create(:invitation, family: family, expires_at: 1.day.from_now)
      expect(invitation.valid_invitation?).to be true
    end

    it "使用済みなら false" do
      invitation = create(:invitation, family: family, used: true)
      expect(invitation.valid_invitation?).to be false
    end

    it "期限切れなら false" do
      invitation = create(:invitation, family: family, expires_at: 1.day.ago)
      expect(invitation.valid_invitation?).to be false
    end
  end

  describe "#mark_as_used!" do
    it "used を true にする" do
      invitation = create(:invitation)
      invitation.mark_as_used!
      expect(invitation.reload.used).to be true
    end
  end
end
