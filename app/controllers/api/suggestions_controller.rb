module Api
  class SuggestionsController < ApplicationController
    wrap_parameters false
    before_action :authenticate_user!
    before_action :set_family, only: [ :create ]
    before_action :validate_cook, only: [ :create ]

    # POST /api/suggestions
    # Suggestion を保存し、AI生成をバックグラウンドジョブにエンキュー
    def create
      budget       = params[:budget]
      cooking_time = params[:cooking_time]
      days         = (params[:days].to_i > 0) ? params[:days].to_i : 1

      constraints = { cooking_time: cooking_time, budget: budget }
      feedback    = fetch_feedback(params[:sgId])

      suggestion = Suggestion.create!(
        family_id: @family.id,
        requests: constraints.compact_blank,
        proposer: @current_member.id,
        status: "pending"
      )

      SuggestionGenerateJob.perform_later(
        suggestion.id,
        @family.id,
        feedback,
        constraints.compact_blank,
        days
      )

      render json: { id: suggestion.id, status: "pending" }, status: :accepted
    end

    # GET /api/suggestions/:id
    # フロントエンドからのポーリング用
    def show
      suggestion = Suggestion.find(params[:id])

      case suggestion.status
      when "completed"
        render json: {
          id: suggestion.id,
          status: suggestion.status,
          suggest_field: JSON.parse(suggestion.ai_raw_json)
        }
      when "failed"
        render json: {
          id: suggestion.id,
          status: suggestion.status,
          error: "AI生成に失敗しました"
        }
      else
        render json: {
          id: suggestion.id,
          status: suggestion.status
        }
      end
    end

    # POST /api/suggestions/:id/feedback
    def feedback
      suggestion = Suggestion.find(params[:id])
      suggestion.update!(
        chosen_option: params[:chosenOption],
        feedback: params[:feedbackNote]
      )

      head :no_content
    end

    private

    # ── before_action ──

    def set_family
      @family = @current_user.family
      render json: { error: "家族が見つかりません" }, status: :bad_request unless @family
    end

    def validate_cook
      @current_member = @current_user.member
      return render json: { error: "メンバーが見つかりません" }, status: :bad_request unless @current_member
      unless @family.today_cook_id == @current_member.id
        render json: { error: "今日の料理担当者ではありません" }, status: :forbidden
      end
    end

    def fetch_feedback(sg_id)
      sg_id.present? ? Suggestion.find(sg_id).feedback : {}
    end
  end
end
