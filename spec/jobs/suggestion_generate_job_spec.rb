require 'rails_helper'

RSpec.describe SuggestionGenerateJob, type: :job do
  let!(:family)  { create(:family) }
  let!(:member)  { create(:member, family: family) }
  let!(:suggestion) { create(:suggestion, family: family, proposer: member.id, status: "pending") }

  let(:ai_response) do
    {
      "choices" => [ {
        "message" => {
          "content" => '{"options":[{"dish_name":"カレー","reason":"家族が好き"}]}'
        }
      } ]
    }
  end

  before do
    client_double = instance_double(OpenAI::Client)
    allow(OpenAI::Client).to receive(:new).and_return(client_double)
    allow(client_double).to receive(:chat).and_return(ai_response)
  end

  describe "#perform" do
    it "正常に実行されると status が completed になる" do
      described_class.new.perform(
        suggestion.id,
        family.id,
        {},
        { "cooking_time" => "30" },
        1
      )

      suggestion.reload
      expect(suggestion.status).to eq("completed")
      expect(suggestion.ai_raw_json).to be_present
    end

    it "OpenAI 呼び出し中にエラーが発生すると status が failed になる" do
      allow(OpenAI::Client).to receive(:new).and_raise(StandardError, "API Error")

      expect {
        described_class.new.perform(suggestion.id, family.id, {}, {}, 1)
      }.to raise_error(StandardError)

      expect(suggestion.reload.status).to eq("failed")
    end

    it "複数日（days > 1）のプロンプトで正常に実行される" do
      described_class.new.perform(
        suggestion.id,
        family.id,
        {},
        { "cooking_time" => "30", "budget" => "1500" },
        3
      )

      suggestion.reload
      expect(suggestion.status).to eq("completed")
      expect(suggestion.ai_raw_json).to be_present
    end

    it "制約条件（budget + cooking_time）が含まれるプロンプトで正常に実行される" do
      described_class.new.perform(
        suggestion.id,
        family.id,
        { "note" => "辛いのが良い" },
        { "cooking_time" => "45", "budget" => "2000" },
        1
      )

      suggestion.reload
      expect(suggestion.status).to eq("completed")
    end

    it "フィードバック付きで正常に実行される" do
      described_class.new.perform(
        suggestion.id,
        family.id,
        "前回は味が薄かった",
        {},
        1
      )

      suggestion.reload
      expect(suggestion.status).to eq("completed")
    end
  end

  describe "キュー設定" do
    it "default キューに入る" do
      expect(described_class.new.queue_name).to eq("default")
    end
  end

  describe "enqueue" do
    it "ActiveJob としてキューに登録できる" do
      expect {
        described_class.perform_later(suggestion.id, family.id, {}, {}, 1)
      }.to have_enqueued_job(described_class)
        .with(suggestion.id, family.id, {}, {}, 1)
        .on_queue("default")
    end
  end
end
