module Api
  class MembersController < ApplicationController
    before_action :authenticate_user!

    def index
      family = @current_user.family
      members = family ? family.members.includes(:likes, :dislikes) : Member.none
      
      render json: members.as_json(
        only: [:id, :name],
        include: {
          likes: { only: [:id, :name]},
          dislikes: { only: [:id, :name]}
        }
      ), status: :ok
    end

    def show
      member = Member.where(family_id: @current_user.family_id)
                     .includes(:likes, :dislikes)
                     .find_by(id: params[:id])

      return render_unauthorized("権限がありません") unless member
      # user_id がある場合は本人のみ、無い場合は同じ family なら許可
      if member.user_id.present? && member.user_id != @current_user.id
        return render_unauthorized("権限がありません")
      end

      render json: member.as_json(
        include: {
          likes: { only: [:id, :name] },
          dislikes: { only: [:id, :name] },
          user: { only: [:id, :firebase_uid] }
        }
      )
    end

    def create
      # flag を先に解釈してから member 作成に反映する
      link_user = params.key?(:link_user) ? ActiveModel::Type::Boolean.new.cast(params[:link_user]) : true
      ActiveRecord::Base.transaction do
        # family_id が params に含まれている場合は既存ファミリーを使用、無い場合は新規作成
        if params[:family_id].present?
          family = Family.find_by(id: params[:family_id])
          return render json: { error: "ファミリーが見つかりません" }, status: :bad_request unless family
        else
          family = Family.create!(name: params.dig(:family, :name))
        end

        # link_user が true のときだけ user を紐付ける
        member_attrs = member_params
        member_attrs = member_attrs.merge(user: @current_user) if link_user
        member = family.members.create!(member_attrs)
        # current_userに紐付け
        @current_user.update!(family: family, member: member) if link_user && @current_user.present?

        render json: member.as_json(include: [:likes, :dislikes, family: { only: [:id, :name] }]), status: :created
      rescue ActiveRecord::RecordInvalid => e
        render json: { errors: e.record.errors.full_messages }, status: :unprocessable_entity
      end
    end

    def update
      member = Member.where(family_id: @current_user.family_id)
                     .find_by(id: params[:id])

      return render_unauthorized("権限がありません") unless member
      # user_id がある場合は本人のみ、無い場合は同じ family なら許可
      if member.user_id.present? && member.user_id != @current_user.id
        return render_unauthorized("権限がありません")
      end

      if member.update(member_params)
        Rails.logger.info "Member updated successfully"
        render json: member.as_json(include: [:likes, :dislikes]), status: :ok
      else
        Rails.logger.error "Member update failed: #{member.errors.full_messages}"
        render json: { errors: member.errors.full_messages }, status: :unprocessable_entity
      end
    end

    def destroy
      member = Member.where(family_id: @current_user.family_id)
                     .find_by(id: params[:id])

      return render_unauthorized("権限がありません") unless member
      # user_id がある場合は本人のみ、無い場合は同じ family なら許可
      if member.user_id.present? && member.user_id != @current_user.id
        return render_unauthorized("権限がありません")
      end

      member.destroy
      head :no_content
    end

    def me
      family = @current_user.family
      # current_member を事前ロード（likes/dislikes）して安全に返す
      current_member = Member.includes(:likes, :dislikes).find_by(user_id: @current_user.id)
      # current_member = @current_user.member

      render json: {
        family_id: family&.id,
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
