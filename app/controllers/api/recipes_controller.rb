class Api::RecipesController < ApplicationController
  wrap_parameters false
  before_action :authenticate_user!

  # POST /api/recipes/explain
  # フロントエンドから送られた料理名の作り方をAIに説明してもらう
  def explain
    dish_name     = params[:dish_name]
    servings      = params[:servings]

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

    parsed = JSON.parse(ai_result)

    render json: { recipe: parsed }
  rescue JSON::ParserError
    render json: { recipe: ai_result }
  end

  # GET /api/recipes
  # 全献立一覧を取得する
  def index
    recipes = Recipe.includes(:family).order(created_at: :desc)

    render json: recipes.map { |r|
      {
        id: r.id,
        dish_name: r.dish_name,
        family_name: r.family&.name,
        reason: r.reason,
        servings: r.servings,
        missing_ingredients: r.missing_ingredients,
        cooking_time: r.cooking_time,
        steps: r.steps,
        proposer_id: r.proposer,
        created_at: r.created_at
      }
    }, status: :ok
  end

  # GET /api/recipes/family
  # 家族ごとの献立一覧を取得する
  def family_recipes
    family = @current_user.family
    return render json: { error: "家族が見つかりません" }, status: :bad_request unless family

    recipes = Recipe.where(family_id: family.id).order(created_at: :desc)

    render json: recipes.map { |r|
      {
        id: r.id,
        dish_name: r.dish_name,
        reason: r.reason,
        servings: r.servings,
        missing_ingredients: r.missing_ingredients,
        cooking_time: r.cooking_time,
        steps: r.steps,
        proposer_id: r.proposer,
        created_at: r.created_at
      }
    }, status: :ok
  end

  # POST /api/recipe/save_recipe
  # レシピを保存する
  def save_recipe
    dish_name = params[:dish_name]
    return render json: { error: "料理名を入力してください" }, status: :bad_request if dish_name.blank?

    family = @current_user.family
    current_member = @current_user.member

    recipe = Recipe.create!(
      dish_name: dish_name,
      proposer: params[:proposer],
      family_id: family&.id,
      servings: params[:servings],
      missing_ingredients: params[:missing_ingredients],
      cooking_time: params[:cooking_time],
      steps: params[:steps],
      suggestion_id: params[:suggestion_id],
      reason: params[:reason]
    )

    render json: { id: recipe.id, message: "レシピを保存しました" }, status: :created
  end

  # GET /api/recipes/:id
  # レシピを取得する
  def get_recipe
    recipe_id = params[:id]
    return render json: { error: "レシピIDを入力してください" }, status: :bad_request if recipe_id.blank?

    recipe = Recipe.find_by(id: recipe_id)
    return render json: { error: "レシピが見つかりません" }, status: :not_found unless recipe

    render json: {
      id: recipe.id,
      dish_name: recipe.dish_name,
      reason: recipe.reason,
      servings: recipe.servings,
      missing_ingredients: recipe.missing_ingredients,
      cooking_time: recipe.cooking_time,
      steps: recipe.steps,
      proposer_id: recipe.proposer,
      created_at: recipe.created_at
    }, status: :ok
  end

  # POST /api/recipe/:id
  # レシピを更新する
  def update
    recipe_id = params[:id]
    return render json: { error: "レシピIDを入力してください" }, status: :bad_request if recipe_id.blank?

    recipe = Recipe.find_by(id: recipe_id)
    return render json: { error: "レシピが見つかりません" }, status: :not_found unless recipe

    recipe.update!(
      servings: params[:servings],
      missing_ingredients: params[:missing_ingredients],
      cooking_time: params[:cooking_time],
      steps: params[:steps]
    )

    render json: { id: recipe.id, message: "レシピを更新しました" }, status: :ok
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
