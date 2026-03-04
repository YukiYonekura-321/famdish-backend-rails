require 'rails_helper'

RSpec.describe Contact, type: :model do
  describe "バリデーション" do
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:email) }
    it { is_expected.to validate_presence_of(:subject) }
    it { is_expected.to validate_presence_of(:message) }

    it "有効なメールアドレスを受け入れる" do
      contact = build(:contact, email: "test@example.com")
      expect(contact).to be_valid
    end

    it "無効なメールアドレスを拒否する" do
      contact = build(:contact, email: "invalid-email")
      expect(contact).not_to be_valid
    end
  end

  describe "ファクトリ" do
    it "有効なファクトリを持つ" do
      expect(build(:contact)).to be_valid
    end
  end
end
