class Api::RecipesController < ApplicationController
  wrap_parameters false
  before_action :authenticate_user!

  # POST /api/recipes/explain
  # フロントエンドから送られた料理名の作り方をAIに説明してもらう
  def explain
    dish_name = params[:dish_name]
    servings  = params[:servings]

    # バリデーション
    return render json: { error: "料理名を入力してください" }, status: :bad_request if dish_name.blank?
    return render json: { error: "何人分か入力してください" }, status: :bad_request if servings.blank?

    # 冷蔵庫の在庫を取得（不足食材の判定に使用）
    family = @current_user.family
    stock_list = if family
                   Stock.where(family_id: family.id).map { |s| { name: s.name, quantity: s.quantity.to_f, unit: s.unit } }
                 else
                   []
                 end

    # プロンプト生成
    prompt = build_recipe_prompt(dish_name, servings, stock_list)

    # OpenAI API 呼び出し
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

    ai_result = response.dig("choices", 0, "message", "content")

    render json: { recipe: JSON.parse(ai_result) }
  rescue JSON::ParserError
    render json: { recipe: ai_result }
  end

  private

  def build_recipe_prompt(dish_name, servings, stock_list)
    <<~PROMPT
    「#{dish_name}」の作り方を#{servings}人分でJSON形式で返してください。
    出力は必ず純粋なJSONのみを返してください。コードブロック（```）や追加説明は一切含めないでください。

    ▼冷蔵庫の在庫
    #{stock_list.to_json}

    ▼返す形式（厳守）
    {
      "dish_name": "#{dish_name}",
      "servings": #{servings},
      "missing_ingredients": [
        { "name": "食材名", "quantity": "必要量（例：200g、2個）" }
      ],
      "cooking_time": 調理時間（分単位の整数）,
      "steps": [
        { "step": 1, "description": "手順の説明" },
        { "step": 2, "description": "手順の説明" }
      ]
    }

    【missing_ingredients について】
    ・この料理に必要な全食材と冷蔵庫の在庫を比較してください。
    ・冷蔵庫に十分な量がある食材は含めないでください。
    ・冷蔵庫にないか、量が足りない食材のみを「不足分の量」で記載してください。
    ・塩、砂糖、醤油、味噌、酒、みりん、油、こしょう、酢などの基本調味料は常備とみなし、missing_ingredientsに含めないでください。

    【cooking_time について】
    ・下準備から完成までの合計時間を分単位の整数で返してください。

    【steps について】
    ・初心者にもわかりやすく、具体的な手順を記載してください。
    ・火加減や時間の目安も含めてください。
    PROMPT
  end
end
