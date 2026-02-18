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
    suggestions = Suggestion.includes(:family)
                           .where(chosen_option: "ok")
                           .order(created_at: :desc)

    render json: suggestions.map { |s|
      {
        id: s.id,
        family_id: s.family_id,
        family_name: s.family&.name,
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
    # requests は必須ではないため、未指定の場合は空配列にする
    requests     = params[:requests] || []     # ["カレー","サラダ","パスタ","肉"]
    id           = params[:sgId] || {}
    servings     = params[:servings]     # 何人分か（例: 4）
    budget       = params[:budget]       # 希望する予算（例: 1500）
    cooking_time = params[:cooking_time] # 希望する調理時間（例: 30）
    days         = (params[:days].to_i > 0) ? params[:days].to_i : 1  # 何日分か（デフォルト1）

    constraints = {
      servings: servings,
      budget: budget,
      cooking_time: cooking_time
    }

    # 過去のフィードバック取得
    feedback = id.present? ? Suggestion.find(id).feedback : {}

    # OpenAIへ投げるプロンプトを作成
    prompt = build_prompt(family_id, requests, feedback, constraints, days)

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
  def build_prompt(family_id, requests, feedback, constraints = {}, days = 1)
    # requests が nil の場合に備えて空配列で初期化
    requests ||= []
    members = Member.where(family_id: family_id)
    stocks  = Stock.where(family_id: family_id)

    likes    = members.map { |m| { name: m.name, likes: m.likes } }
    dislikes = members.map { |m| { name: m.name, dislikes: m.dislikes } }
    stock_list = stocks.map { |s| { name: s.name, quantity: s.quantity.to_f, unit: s.unit } }

    # 制約条件テキスト生成
    constraint_lines = []
    constraint_lines << "・#{constraints[:servings]}人分" if constraints[:servings].present?
    constraint_lines << "・予算: #{constraints[:budget]}円以内" if constraints[:budget].present?
    constraint_lines << "・調理時間: #{constraints[:cooking_time]}分以内" if constraints[:cooking_time].present?

    if days > 1
      build_multi_day_prompt(likes, dislikes, stock_list, requests, feedback, constraint_lines, days)
    else
      build_single_day_prompt(likes, dislikes, stock_list, requests, feedback, constraint_lines)
    end
  end

  def build_single_day_prompt(likes, dislikes, stock_list, requests, feedback, constraint_lines)
    # requests が空の場合は明示的な指示を追加
    requests ||= []
    request_display = requests.present? ? requests.to_json : "[]"
    request_instruction = requests.present? ? "" : "※希望の献立が未指定のため、家族の好みと在庫を優先して提案してください。"

    <<~PROMPT
    あなたは厳密な制約チェッカー兼献立提案AIです。
    出力は必ず純粋なJSONのみを返してください。コードブロック（```）や追加説明は一切含めないでください。

    【最重要ルール】
    以下の制約条件を必ず最初に検証してください。
    1つでも満たせない制約がある場合は、献立を提案せず、必ず「料理は作れません」形式で返してください。
    制約を無視して無理やり献立を提案することは禁止です。

    ▼家族の好み
    好き：#{likes.to_json}
    嫌い：#{dislikes.to_json}

    ▼冷蔵庫の在庫（この在庫だけで調味料も含め料理が作れるか判断してください）
    #{stock_list.to_json}

    ▼制約条件（すべて満たす必要があります）
    #{constraint_lines.any? ? constraint_lines.join("\n") : "特になし"}

    ▼今日のリクエスト
    #{request_display}
    #{request_instruction}

    ▼過去のフィードバック
    #{feedback.to_json}

    ▼返す形式（厳守）
    まず制約条件をすべて検証し、1つでも満たせない場合は以下のいずれかを返してください。
    絶対に制約を超えた献立を提案しないでください。
    
    【在庫がない・足りない場合】
    {
      "title": "料理は作れません",
      "reason": "在庫がありません",
      "ingredients": ["必要な材料1", "必要な材料2"],
      "requests": #{request_display}
    }
    
    【予算が足りない場合】
    {
      "title": "料理は作れません",
      "reason": "予算が〇〇円足りません",
      "ingredients": ["必要な材料1", "必要な材料2"],
      "requests": #{request_display}
    }
    
    【調理時間が足りない場合】
    {
      "title": "料理は作れません",
      "reason": "調理時間が〇〇分足りません",
      "ingredients": ["必要な材料1", "必要な材料2"],
      "requests": #{request_display}
    }
    
    【制約条件をすべて満たす場合】
    {
      "title": "string",
      "reason": "string",
      "time": この料理の調理時間（分単位の整数。材料と調理方法から適切に推定してください）,
      "ingredients": ["材料1", "材料2"],
      "requests": #{request_display}
    }
    PROMPT
  end

  def build_multi_day_prompt(likes, dislikes, stock_list, requests, feedback, constraint_lines, days)
    # requests が空の場合は明示的な指示を追加
    requests ||= []
    request_display = requests.present? ? requests.to_json : "[]"
    request_instruction = requests.present? ? "" : "※希望の献立が未指定のため、家族の好みと在庫を優先して提案してください。"

    <<~PROMPT
    あなたは厳密な制約チェッカー兼献立提案AIです。
    出力は必ず純粋なJSONのみを返してください。コードブロック（```）や追加説明は一切含めないでください。

    【最重要ルール】
    以下の制約条件を必ず最初に検証してください。
    1つでも満たせない制約がある場合は、献立を提案せず、必ず「料理は作れません」形式で返してください。
    制約を無視して無理やり献立を提案することは禁止です。
    #{days}日分の献立が重複しないよう、バリエーション豊かに提案してください。
    在庫を考慮し、#{days}日間で効率的に使い切れるよう工夫してください。

    ▼家族の好み
    好き：#{likes.to_json}
    嫌い：#{dislikes.to_json}

    ▼冷蔵庫の在庫（この在庫だけで調味料も含め料理が作れるか判断してください）
    #{stock_list.to_json}

    ▼制約条件（1日あたり。すべて満たす必要があります）
    #{constraint_lines.any? ? constraint_lines.join("\n") : "特になし"}

    ▼リクエスト
    #{request_display}
    #{request_instruction}

    ▼過去のフィードバック
    #{feedback.to_json}

    ▼返す形式（厳守）
    まず制約条件をすべて検証し、1つでも満たせない場合は以下のいずれかを返してください。
    絶対に制約を超えた献立を提案しないでください。
    
    【在庫がない・足りない場合】
    [
      {
        "day": 1,
        "title": "料理は作れません",
        "reason": "在庫がありません",
        "ingredients": ["必要な材料1", "必要な材料2"],
        "requests": #{request_display}
      }
    ]
    
    【予算が足りない場合】
    [
      {
        "day": 1,
        "title": "料理は作れません",
        "reason": "予算が〇〇円足りません",
        "ingredients": ["必要な材料1", "必要な材料2"],
        "requests": #{request_display}
      }
    ]
    
    【調理時間が足りない場合】
    [
      {
        "day": 1,
        "title": "料理は作れません",
        "reason": "調理時間が〇〇分足りません",
        "ingredients": ["必要な材料1", "必要な材料2"],
        "requests": #{request_display}
      }
    ]
    
    【制約条件をすべて満たす場合】#{days}日分の異なる献立を返してください
    [
      {
        "day": 1,
        "title": "string",
        "reason": "string",
        "time": この日の料理の調理時間（分単位の整数。材料と調理方法から適切に推定してください）,
        "ingredients": ["材料1", "材料2"],
        "requests": #{request_display}
      },
      {
        "day": 2,
        "title": "string",
        "reason": "string",
        "time": この日の料理の調理時間（分単位の整数。材料と調理方法から適切に推定してください）,
        "ingredients": ["材料1", "材料2"],
        "requests": #{request_display}
      }
    ]
    PROMPT
  end
end
