require 'rails_helper'

RSpec.describe Dislike, type: :model do
  describe "アソシエーション" do
    it { is_expected.to belong_to(:member) }
  end
end
