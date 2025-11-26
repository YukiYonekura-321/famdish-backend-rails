class Api::SuggestionsController < ApplicationController
  wrap_parameters false
  def create
    family_id = @current_user.family&.id

    # フロントから渡されるパラメータ
    requests      = params[:requests] # ["カレー","サラダ","パスタ","肉"]
    constraints   = params[:constraints] || {}

    # OpenAIへ投げるプロンプトを作成
    prompt = build_prompt(family_id, requests, constraints)

    # プロンプトをコンソールに表示
    puts(prompt)

    # OpenAI API 呼び出し
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

    # AIが返したJSON（string）を抽出
    ai_result = response.dig("choices", 0, "message", "content")

    # suggestionsテーブルに保存
    suggestion = Suggestion.create!(
      family_id: family_id,
      requests: requests,
      ai_raw_json: ai_result
    )

    # そのまま返す
    render json: { id: suggestion.id, suggestions: JSON.parse(ai_result) }
  end

  private

  # GPTに渡すプロンプト生成
  def build_prompt(family_id, requests, constraints)
    members = Member.where(family_id: family_id)

    likes  = members.map { |m| { name: m.name, likes: m.likes } }
    dislikes = members.map { |m| { name: m.name, dislikes: m.dislikes } }

    <<~PROMPT
    家族構成と今日のリクエストをもとに、献立案を3つJSONで返してください。
    出力は必ず純粋なJSONのみを返してください。コードブロック（```）や追加説明は一切含めないでください。

    ▼家族の好み
    好き：#{likes.to_json}
    嫌い：#{dislikes.to_json}

    ▼今日のリクエスト
    #{requests.to_json}

    ▼制約
    #{constraints.to_json}

    ▼返す形式（厳守）
    {
      "suggestions": [
        {
          "title": "string",
          "reason": "string",
          "time": 30,
          "ingredients": ["材料1", "材料2"]
        }
      ]
    }
    PROMPT
  end
end
