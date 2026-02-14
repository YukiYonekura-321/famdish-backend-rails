class Api::SuggestionsController < ApplicationController
  wrap_parameters false
  before_action :authenticate_user!

  # GET /api/suggestions/check
  # 指定された家族の過去の献立（chosen_option: "ok"）を全て返す
  def check
    family = @current_user.family
    return render json: [], status: :ok unless family

    suggestions = Suggestion.where(family_id: family.id, chosen_option: "ok")
                           .order(created_at: :desc)

    render json: suggestions.map { |s|
      {
        id: s.id,
        family_id: s.family_id,
        requests: s.requests,
        ai_raw_json: JSON.parse(s.ai_raw_json),
        chosen_option: s.chosen_option,
        feedback: s.feedback,
        proposer_id: s.proposer,
        created_at: s.created_at
      }
    }, status: :ok
  end

  # GET /api/suggestions
  # 全家族の献立（chosen_option: "ok"）を返す（他の家族の献立も参考に）
  def index
    suggestions = Suggestion.where(chosen_option: "ok")
                           .order(created_at: :desc)

    render json: suggestions.map { |s|
      {
        id: s.id,
        family_id: s.family_id,
        requests: s.requests,
        ai_raw_json: JSON.parse(s.ai_raw_json),
        chosen_option: s.chosen_option,
        feedback: s.feedback,
        proposer_id: s.proposer,
        created_at: s.created_at
      }
    }, status: :ok
  end
  

  def create
    current_member = @current_user.member
    family = @current_user.family

    # バリデーション：今日の料理担当者のみ献立提案を作成できる
    return render json: { error: "家族が見つかりません" }, status: :bad_request unless family
    return render json: { error: "メンバーが見つかりません" }, status: :bad_request unless current_member
    unless family.today_cook_id == current_member.id
      return render json: { error: "今日の料理担当者ではありません" }, status: :forbidden
    end

    family_id = family.id

    # フロントから渡されるパラメータ
    requests      = params[:requests] # ["カレー","サラダ","パスタ","肉"]
    id   = params[:sgId] || {}

    # OpenAIへ投げるプロンプトを作成
    if id.present?
      feedback = Suggestion.find(id).feedback
      prompt = build_prompt(family_id, requests, feedback)
    else
      prompt = build_prompt(family_id, requests, {})

    end

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
      ai_raw_json: ai_result,
      proposer: current_member.id
    )

    # そのまま返す
    render json: { id: suggestion.id, suggest_field: JSON.parse(ai_result) }
  end


  def feedback
    suggestion = Suggestion.find(params[:id])

    suggestion.update!(
      chosen_option: params[:chosenOption],   # ["OK","alt"]
      feedback: params[:feedbackNote]  # "良かった点、悪かった点など"
    )

    render json: { message: "saved" }
  end

  private

  # GPTに渡すプロンプト生成
  def build_prompt(family_id, requests, feedback)
    members = Member.where(family_id: family_id)

    likes  = members.map { |m| { name: m.name, likes: m.likes } }
    dislikes = members.map { |m| { name: m.name, dislikes: m.dislikes } }

    <<~PROMPT
    家族構成と今日のリクエストをもとに、献立案を1つJSONで返してください。
    出力は必ず純粋なJSONのみを返してください。コードブロック（```）や追加説明は一切含めないでください。

    ▼家族の好み
    好き：#{likes.to_json}
    嫌い：#{dislikes.to_json}

    ▼今日のリクエスト
    #{requests.to_json}

    ▼過去のフィードバック
    #{feedback.to_json}

    ▼返す形式（厳守）
    {
      "title": "string",
      "reason": "string",
      "time": 30,
      "ingredients": ["材料1", "材料2"],
      "requests": #{requests}
    }
    PROMPT
  end
end
