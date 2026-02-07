module Api
  class MembersController < ApplicationController
    before_action :authenticate_user!

    def index
      members = Member.all
      render json: members.as_json(include: [:likes, :dislikes])
    end

    def show
      member = Member.find(params[:id])
      render json: member.as_json(
        include: {
          likes: { only: [:id, :name] },
          dislikes: { only: [:id, :name] },
          user: { only: [:id, :firebase_uid] }
        }
      )
    rescue ActiveRecord::RecordNotFound
      render_unauthorized("メンバーが見つかりません")
    end

    def create
      ActiveRecord::Base.transaction do
        # Family を作成
        family = Family.create!(name: params[:family][:name])

        # Member を作成
        member = family.members.create!(member_params.merge(user: @current_user))

        # デフォルトで current_user に紐付けする。フロントが link_user=false を渡せば紐付けしない
        link_user = params.key?(:link_user) ? ActiveModel::Type::Boolean.new.cast(params[:link_user]) : true

        # current_userに紐付け
        @current_user.update!(family: family, member: member) if link_user && @current_user.present?

        render json: member.as_json(include: [:likes, :dislikes, family: { only: [:id, :name] }]), status: :created
      rescue ActiveRecord::RecordInvalid => e
        render json: { errors: e.record.errors.full_messages }, status: :unprocessable_entity
      end
    end

    def update
      member = Member.find(params[:id])
      if member.update(member_params)
        Rails.logger.info "Member updated successfully"
        render json: member.as_json(include: [:likes, :dislikes]), status: :ok
      else
        Rails.logger.error "Member update failed: #{member.errors.full_messages}"
        render json: { errors: member.errors.full_messages }, status: :unprocessable_entity
      end
    rescue ActiveRecord::RecordNotFound
      render_unauthorized("メンバーが見つかりません")
    end

    def destroy
      member = Member.find(params[:id])
      member.destroy
      head :no_content
    rescue ActiveRecord::RecordNotFound
      render_unauthorized("メンバーが見つかりません")
    end

    def me
      family = @current_user.family
      # current_member を事前ロード（likes/dislikes）して安全に返す
      current_member = Member.includes(:likes, :dislikes).find_by(user_id: @current_user.id)
      # current_member = @current_user.member

      render json: {
        family_name: family&.name,
        username: current_member&.name,
        member: current_member&.as_json(
          only: [:id, :name],
          # includeでN + 1問題を回避
          include: {
            likes: { only: [:id, :name] },
            dislikes: { only: [:id, :name] }
          }
        )
      }, status: :ok
    end

    private

    def member_params
      params.require(:member).permit(
        :name,
        likes_attributes: [:id, :name, :_destroy],
        dislikes_attributes: [:id, :name, :_destroy]
      )
    end
  end
end
