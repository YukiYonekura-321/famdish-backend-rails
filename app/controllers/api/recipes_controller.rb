module Api
  class RecipesController < ApplicationController
    wrap_parameters false
    before_action :authenticate_user!
    before_action :set_recipe, only: [ :show, :update, :destroy ]

    # POST /api/recipes/explain
    def explain
      dish_name    = params[:dish_name]
      servings     = params[:servings]
      cooking_time = fetch_cooking_time(params[:suggestion_id])

      Rails.logger.info "[RecipesController] dish_name=#{dish_name}, servings=#{servings}, suggestion_id=#{params[:suggestion_id]}, cooking_time=#{cooking_time}"

      return render json: { error: "料理名を入力してください" }, status: :bad_request if dish_name.blank?
      return render json: { error: "何人分か入力してください" }, status: :bad_request if servings.blank?

      prompt = build_recipe_prompt(dish_name, servings, stock_list, cooking_time: cooking_time)
      Rails.logger.info "[RecipesController] Prompt:\n#{prompt}"
      ai_result = call_openai(prompt)
      parsed = JSON.parse(ai_result)

      render json: { recipe: parsed }
    rescue JSON::ParserError
      render json: { recipe: ai_result }
    end

    # GET /api/recipes
    def index
      recipes = Recipe.includes(:family).order(created_at: :desc)
      render json: recipes.map { |r| recipe_list_json(r, include_family: true) }, status: :ok
    end

    # GET /api/recipes/family
    def family
      family = @current_user.family
      return render json: { error: "家族が見つかりません" }, status: :bad_request unless family

      recipes = Recipe.where(family_id: family.id).order(created_at: :desc)
      render json: recipes.map { |r| recipe_list_json(r) }, status: :ok
    end

    # POST /api/recipes
    def create
      return render json: { error: "料理名を入力してください" }, status: :bad_request if params[:dish_name].blank?

      recipe = Recipe.create!(
        dish_name: params[:dish_name],
        proposer: params[:proposer],
        family_id: @current_user.family&.id,
        servings: params[:servings],
        suggestion_id: params[:suggestion_id],
        missing_ingredients: params[:missing_ingredients],
        cooking_time: params[:cooking_time],
        steps: params[:steps],
        reason: params[:reason]
      )

      render json: { id: recipe.id, message: "レシピを保存しました" }, status: :created
    end

    # GET /api/recipes/:id
    def show
      render json: recipe_detail_json(@recipe), status: :ok
    end

    # PATCH /api/recipes/:id
    def update
      @recipe.update!(
        servings: params[:servings],
        missing_ingredients: params[:missing_ingredients],
        cooking_time: params[:cooking_time],
        steps: params[:steps]
      )

      head :no_content
    end

    # DELETE /api/recipes/:id
    def destroy
      @recipe.destroy!
      render json: { message: "レシピを削除しました" }, status: :ok
    end

    private

    def set_recipe
      @recipe = Recipe.find_by(id: params[:id])
      render json: { error: "レシピが見つかりません" }, status: :not_found unless @recipe
    end

    def stock_list
      family = @current_user.family
      return [] unless family

      Stock.where(family_id: family.id).map { |s| { name: s.name, quantity: s.quantity.to_f, unit: s.unit } }
    end

    # 一覧用（軽量）: steps, missing_ingredients を省略
    def recipe_list_json(recipe, include_family: false)
      json = {
        id: recipe.id,
        dish_name: recipe.dish_name,
        reason: recipe.reason,
        servings: recipe.servings,
        cooking_time: recipe.cooking_time,
        proposer_id: recipe.proposer,
        suggestion_id: recipe.suggestion_id,
        created_at: recipe.created_at
      }
      json[:family_name] = recipe.family&.name if include_family
      json
    end

    # 詳細用（フル）: show で使用
    def recipe_detail_json(recipe)
      {
        id: recipe.id,
        servings: recipe.servings,
        missing_ingredients: recipe.missing_ingredients,
        cooking_time: recipe.cooking_time,
        steps: recipe.steps
      }
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

    def fetch_cooking_time(suggestion_id)
      return nil if suggestion_id.blank?

      suggestion = Suggestion.find_by(id: suggestion_id)
      suggestion&.requests&.dig("cooking_time")
    end

    def build_recipe_prompt(dish_name, servings, stock_list, cooking_time: nil)
    <<~PROMPT
    「#{dish_name}」の作り方を#{servings}人分でJSON形式で返してください。
    #{ cooking_time.present? ? "制限時間は#{cooking_time}分以内です。この時間内に完成できるレシピにしてください。" : "" }
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
    ・制限時間が指定されている場合は、必ずその時間以内に収まるようにしてください。

    【steps について】
    ・初心者にもわかりやすく、具体的な手順を記載してください。
    ・火加減や時間の目安も含めてください。
    PROMPT
    end
  end
end
