class SuggestionGenerateJob < ApplicationJob
  queue_as :default

  def perform(suggestion_id, family_id, feedback, constraints, days)
    suggestion = Suggestion.find(suggestion_id)
    suggestion.update!(status: "processing")

    prompt = build_prompt(family_id, feedback, constraints.symbolize_keys, days)
    Rails.logger.info "[SuggestionGenerateJob] Prompt:\n#{prompt}"

    ai_result = call_openai(prompt)

    parsed = JSON.parse(ai_result)

    if parsed.is_a?(Array)
      # 複数日の場合、各日のレシピに対して画像生成
      parsed.each do |day_parsed|
        if day_parsed["title"] != "料理は作れません"
          day_parsed["image_url"] = generate_dish_image(day_parsed)
        else
          day_parsed["image_url"] = nil
        end
      end
      representative_image_url = parsed.first&.dig("image_url")
    else
      # 1日分の場合
      if parsed["title"] != "料理は作れません"
        image_url = generate_dish_image(parsed)
        parsed["image_url"] = image_url
      else
        image_url = nil
        parsed["image_url"] = nil
      end
      representative_image_url = image_url
    end

    suggestion.update!(
      ai_raw_json: parsed.to_json,
      status: "completed",
      image_url: representative_image_url
    )
  rescue StandardError => e
    Rails.logger.error "[SuggestionGenerateJob] Failed: #{e.message}"
    suggestion&.update!(status: "failed") if suggestion&.persisted?
    raise # re-raise でリトライ対象に
  end

  private

  def generate_dish_image(parsed)
    prompt_text = build_image_prompt(parsed)
    uri = URI.parse("https://fal.run/fal-ai/flux/schnell")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    request = Net::HTTP::Post.new(uri.request_uri)
    request["Authorization"] = "Key #{ENV['FAL_KEY']}"
    request["Content-Type"] = "application/json"
    request.body = { prompt: prompt_text }.to_json

    response = http.request(request)
    Rails.logger.info("[SuggestionGenerateJob] FAL API Response Status: #{response.code}")
    Rails.logger.info("[SuggestionGenerateJob] FAL API Response Body: #{response.body}")

    data = JSON.parse(response.body)
    Rails.logger.info("[SuggestionGenerateJob] Parsed data: #{data.inspect}")

    # ※fal gemを使用する場合
    # image = Fal.run("fal-ai/flux/schnell", input: { prompt: parsed.to_json })
    # image.dig("images", 0, "url")
    image_url = data.dig("images", 0, "url")
    Rails.logger.info("[SuggestionGenerateJob] Generated image URL: #{image_url}")

    image_url
  rescue => e
    Rails.logger.error("[SuggestionGenerateJob] Image generation error: #{e.message}")
    nil
  end

  def build_image_prompt(parsed)
    title = parsed["title"]
    <<~PROMPT.squish
      A professional food photograph of #{title}.
      Beautifully plated on a white ceramic dish,
      soft warm natural lighting, shallow depth of field,
      food magazine style, photorealistic, 4K, appetizing, delicious.
    PROMPT
  end

  def call_openai(prompt)
    client = OpenAI::Client.new(access_token: ENV["OPENAI_API_KEY"])
    response = client.chat(
      parameters: {
        model: "gpt-4o-mini",
        messages: [
          { role: "system", content: "あなたは料理の献立提案AIです。" },
          { role: "user", content: prompt }
        ],
        temperature: 0.7
      }
    )
    response.dig("choices", 0, "message", "content")
  end

  # ── プロンプト構築 ──

  def build_prompt(family_id, feedback, constraints, days)
    members = Member.where(family_id: family_id).includes(:likes, :dislikes)
    stocks  = Stock.where(family_id: family_id)

    likes      = members.map { |m| { name: m.name, likes: m.likes } }
    dislikes   = members.map { |m| { name: m.name, dislikes: m.dislikes } }
    stock_list = stocks.map { |s| { name: s.name, quantity: s.quantity.to_f, unit: s.unit } }

    constraint_lines = build_constraint_lines(constraints)

    if days > 1
      build_multi_day_prompt(likes, dislikes, stock_list, feedback, constraint_lines, days)
    else
      build_single_day_prompt(likes, dislikes, stock_list, feedback, constraint_lines)
    end
  end

  def build_constraint_lines(constraints)
    lines = []
    lines << "・予算: #{constraints[:budget]}円以内" if constraints[:budget].present?
    lines << "・調理時間: #{constraints[:cooking_time]}分以内" if constraints[:cooking_time].present?
    lines
  end

  def build_single_day_prompt(likes, dislikes, stock_list, feedback, constraint_lines)
  <<~PROMPT
  家族の好み・在庫・制約条件をもとに、献立案を1つJSONで返してください。
  家族の好みと在庫を優先して提案してください。
  出力は必ず純粋なJSONのみを返してください。コードブロックや追加説明は一切含めないでください。

  【判断ルール】
  ・塩、砂糖、醤油、味噌、酒、みりん、油、こしょう、酢などの基本調味料は家庭に常備されているものとし、在庫になくても使用して構いません。
  ・在庫にある食材をなるべく活用してください。
  ・ただし、主要な食材（肉、魚、野菜、米、麺など）が在庫に全くない場合は「料理は作れません」を返してください。
  ・予算や調理時間の制約が指定されている場合、それを明らかに超える料理しか作れない場合は「料理は作れません」を返してください。
  ・制約を満たす献立が可能な場合は、必ず献立を提案してください。

  ▼家族の好み
  好き：#{likes.to_json}
  嫌い：#{dislikes.to_json}

  ▼冷蔵庫の在庫（なるべく在庫を活用してください。基本調味料は常備とみなします）
  #{stock_list.to_json}

  ▼制約条件
  #{constraint_lines.present? ? constraint_lines.first : "特になし"}

  ▼過去のフィードバック
  #{feedback.to_json}

  ▼返す形式（厳守）
  制約条件を検証し、主要食材の不足・予算超過・時間超過で献立が不可能な場合のみ、以下のいずれかを返してください。

  【在庫が足りない場合】
  {
    "title": "料理は作れません",
    "reason": "在庫がありません",
    "ingredients": ["必要な材料1", "必要な材料2"]
  }

  【調理時間が足りない場合】
  {
    "title": "料理は作れません",
    "reason": "調理時間が〇〇分足りません",
    "ingredients": ["必要な材料1", "必要な材料2"]
  }

  【制約条件を満たす場合】
  {
    "title": "string",
    "reason": "具体的な理由（例：「〇〇さんが好きなので」「〇〇の在庫を活用して」など、家族の好みや在庫に基づいた具体的な理由。「制約条件を満たしています」のような当たり前の理由は禁止）",
    "time": この料理の調理時間（分単位の整数。材料と調理方法から適切に推定してください）,
    "budget": この料理の予算（円単位の整数。材料から適切に推定してください）,
    "ingredients": ["材料1", "材料2"]
  }
  PROMPT
  end

  def build_multi_day_prompt(likes, dislikes, stock_list, feedback, constraint_lines, days)
  <<~PROMPT
  家族の好み・在庫・制約条件をもとに、#{days}日分の献立案をJSONの配列で返してください。
  家族の好みと在庫を優先して提案してください。
  出力は必ず純粋なJSONのみを返してください。コードブロックや追加説明は一切含めないでください。

  【判断ルール】
  ・塩、砂糖、醤油、味噌、酒、みりん、油、こしょう、酢などの基本調味料は家庭に常備されているものとし、在庫になくても使用して構いません。
  ・在庫にある食材をなるべく活用してください。
  ・ただし、主要な食材（肉、魚、野菜、米、麺など）が在庫に全くない場合は「料理は作れません」を返してください。
  ・予算や調理時間の制約が指定されている場合、それを明らかに超える料理しか作れない場合は「料理は作れません」を返してください。
  ・制約を満たす献立が可能な場合は、必ず献立を提案してください。
  ・#{days}日分の献立が重複しないよう、バリエーション豊かに提案してください。
  ・在庫を考慮し、#{days}日間で効率的に使い切れるよう工夫してください。

  ▼家族の好み
  好き：#{likes.to_json}
  嫌い：#{dislikes.to_json}

  ▼冷蔵庫の在庫（なるべく在庫を活用してください。基本調味料は常備とみなします）
  #{stock_list.to_json}

  ▼制約条件（1日あたり）
  #{constraint_lines.present? ? constraint_lines.first : "特になし"}

  ▼過去のフィードバック
  #{feedback.to_json}

  ▼返す形式（厳守）
  制約条件を検証し、主要食材の不足・予算超過・時間超過で献立が不可能な場合のみ、以下のいずれかを返してください。

  【在庫が足りない場合】
  [
    {
      "day": 1,
      "title": "料理は作れません",
      "reason": "在庫がありません",
      "ingredients": ["必要な材料1", "必要な材料2"]
    }
  ]

  調理時間が足りない場合】
  [
    {
      "day": 1,
      "title": "料理は作れません",
      "reason": "調理時間が〇〇分足りません",
      "ingredients": ["必要な材料1", "必要な材料2"]
    }
  ]

  【制約条件を満たす場合】#{days}日分の異なる献立を返してください
  [
    {
      "day": 1,
      "title": "string",
      "reason": "具体的な理由（例：「〇〇さんが好きなので」「〇〇の在庫を活用して」など、家族の好みや在庫に基づいた具体的な理由。「制約条件を満たしています」のような当たり前の理由は禁止）",
      "time": この日の料理の調理時間（分単位の整数。材料と調理方法から適切に推定してください）,
      "budget": この日の料理の予算（円単位の整数。材料から適切に推定してください）,
      "ingredients": ["材料1", "材料2"]
    },
    {
      "day": 2,
      "title": "string",
      "reason": "具体的な理由",
      "time": この日の料理の調理時間（分単位の整数）,
      "budget": この日の料理の予算（円単位の整数）,
      "ingredients": ["材料1", "材料2"]
    }
  ]
  PROMPT
  end
end
