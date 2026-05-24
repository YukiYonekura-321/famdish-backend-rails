module Api
  class TrialsController < ApplicationController
    # POST /api/trial/aisuggestion
    def aisuggestion
      likes = params[:likes]
      dislikes = params[:dislikes]

      Rails.logger.info(" [TrialsController] likes=#{likes} dislikes=#{dislikes}")
      return render json: { error: "好きなものを入力してください" }, status: :bad_request if likes.blank?
      render json: { error: "嫌いなものを入力してください" }, status: :bad_request if dislikes.blank?

      prompt = build_ai_prompt(likes, dislikes)
      ai_result = call_openai(prompt)
      parsed = JSON.parse(ai_result)

      render json: { recipe: parsed }
    rescue JSON::ParserError => e
      Rails.logger.info("[TrialController] JSON Parse Error:#{e.message}")
      render json: {
        error: "レシピの生成に失敗しました",
        message: "AIからの応答が正しい形式ではありません",
        response: ai_result[0..200]
       }, status: :unprocessable_entity
    end

    private

    def call_openai(prompt)
      client = OpenAI::Client.new(access_token: ENV["OPENAI_API_KEY"])
      response = client.chat(
        parameters: {
          model: "gpt-4o-mini",
          messages: [
            { role: "system", content: "あなたはプロの料理人です。料理のレシピを正確にJSON形式で返してください。" },
            { role: "user", content: prompt }
          ],
          temperature: 0.7
        }
      )
      response.dig("choices", 0, "message", "content")
    end

    def build_ai_prompt(likes, dislikes)
      <<~PROMPT
      好きなものと嫌いなものを元に最適な献立案を1つJSONで返してください。
      出力は必ず純粋なJSONのみを返してください。コードブロックや追加説明は一切含めないでください。
      ▼好きなもの
      #{likes}
      ▼好きなもの
      #{dislikes}

      ▼返す形式（厳守）
      {
        "title": "string",
        "reason": "具体的な理由（例：「〇〇さんが好きなので」など、好みに基づいた具体的な理由。）",
        "time": この料理の調理時間（分単位の整数。材料と調理方法から適切に推定してください）,
        "budget": この料理の予算（円単位の整数。材料から適切に推定してください）,
        "ingredients": ["材料1", "材料2"]
      }
      PROMPT
    end
  end
end
