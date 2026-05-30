module Api
  class TrialsController < ApplicationController
    skip_before_action :authenticate_user!, only: [ :aisuggestion ]

    TRIAL_LIMIT = 20

    # POST /api/trial/aisuggestion
    def aisuggestion
      firebase_uid = extract_firebase_uid
      return render json: { error: "認証情報がありません" }, status: :unauthorized if firebase_uid.blank?

      trial_usage = TrialUsage.find_or_initialize_for(firebase_uid)
      if trial_usage.limit_exceeded?
        return render json: {
          error: "トライアルの利用回数が上限（#{TRIAL_LIMIT}回）に達しました。アカウント登録してご利用ください。",
          usage_count: trial_usage.usage_count,
          limit: TRIAL_LIMIT
        }, status: :too_many_requests
      end

      likes = params[:likes]
      dislikes = params[:dislikes]

      Rails.logger.info("[TrialsController] firebase_uid=#{firebase_uid} likes=#{likes} dislikes=#{dislikes}")
      return render json: { error: "好きなものを入力してください" }, status: :bad_request if likes.blank?
      return render json: { error: "嫌いなものを入力してください" }, status: :bad_request if dislikes.blank?

      prompt = build_ai_prompt(likes, dislikes)
      ai_result = call_openai(prompt)
      parsed = JSON.parse(ai_result)

      trial_usage.save! if trial_usage.new_record?
      trial_usage.increment!

      image_url = generate_dish_image(parsed)

      render json: {
        sample: parsed,
        image_url: image_url,
        usage_count: trial_usage.usage_count,
        limit: TRIAL_LIMIT
      }
    rescue JSON::ParserError => e
      Rails.logger.error("[TrialsController] JSON Parse Error: #{e.message}")
      render json: {
        error: "レシピの生成に失敗しました",
        message: "AIからの応答が正しい形式ではありません",
        response: ai_result[0..200]
      }, status: :unprocessable_entity
    end

    private

    def generate_dish_image(parsed)
      uri = URI.parse("https://fal.run/fal-ai/flux/schnell")
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true

      request = Net::HTTP::Post.new(uri.request_uri)
      request["Authorization"] = "Key #{ENV['FAL_KEY']}"
      request["Content-Type"] = "application/json"
      request.body = { prompt: parsed }.to_json

      response = http.request(request)
      Rails.logger.info("[TrialsController] FAL API Response Status: #{response.code}")
      Rails.logger.info("[TrialsController] FAL API Response Body: #{response.body}")

      data = JSON.parse(response.body)
      Rails.logger.info("[TrialsController] Parsed data: #{data.inspect}")

      # ※fal gemを使用する場合
      # image = Fal.run("fal-ai/flux/schnell", input: { prompt: parsed.to_json })
      # image.dig("images", 0, "url")
      image_url = data.dig("images", 0, "url")
      Rails.logger.info("[TrialsController] Generated image URL: #{image_url}")

      image_url
    rescue => e
      Rails.logger.error("[TrialsController] Image generation error: #{e.message}")
      nil
    end

    def extract_firebase_uid
      token = request.headers["Authorization"]&.split(" ")&.last
      return nil if token.blank?

      verified = FirebaseIdToken::Signature.verify(token)
      verified&.dig("user_id")
    rescue FirebaseIdToken::Exceptions::NoCertificatesError
      FirebaseIdToken::Certificates.request!
      verified = FirebaseIdToken::Signature.verify(token)
      verified&.dig("user_id")
    rescue => e
      Rails.logger.error("[TrialsController] Firebase token error: #{e.message}")
      nil
    end

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
      ▼嫌いなもの
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
