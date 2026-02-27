module Api
  class MembersController < ApplicationController
    before_action :authenticate_user!
    before_action :set_authorized_member, only: [:update, :destroy]

    # GET /api/members
    def index
      family = @current_user.family
      members = family ? family.members.includes(:likes, :dislikes, :menus) : Member.none

      render json: members.as_json(
        only: [:id, :name],
        include: {
          likes: { only: [:name] },
          dislikes: { only: [:name] },
          user: { only: [:firebase_uid] },
          menus: { only: [:name] }
        }
      ), status: :ok
    end

    # POST /api/members
    def create
      link_user = params.key?(:link_user) ? ActiveModel::Type::Boolean.new.cast(params[:link_user]) : true

      ActiveRecord::Base.transaction do
        family = find_or_create_family
        return unless family

        member_attrs = member_params
        member_attrs = member_attrs.merge(user: @current_user) if link_user
        member = family.members.create!(member_attrs)

        @current_user.update!(family: family, member: member) if link_user

        render json: member.as_json(include: [:likes, :dislikes, family: { only: [:id, :name] }]), status: :created
      rescue ActiveRecord::RecordInvalid => e
        render json: { errors: e.record.errors.full_messages }, status: :unprocessable_entity
      end
    end

    # PATCH /api/members/:id
    def update
      if @member.update(member_params)
        head :no_content
      else
        render json: { errors: @member.errors.full_messages }, status: :unprocessable_entity
      end
    end

    # DELETE /api/members/:id
    def destroy
      @member.destroy
      head :no_content
    end

    # GET /api/members/me
    def me
      family = @current_user.family
      current_member = Member.includes(:likes, :dislikes).find_by(user_id: @current_user.id)

      render json: {
        family_id: family&.id,
        family_name: family&.name,
        username: current_member&.name,
        member: current_member&.as_json(only: [:id])
      }, status: :ok
    end

    # GET /api/members/all
    def all
      render json: Member.all.as_json(only: [:id, :name]), status: :ok
    end

    private

    def set_authorized_member
      @member = Member.where(family_id: @current_user.family_id)
                      .find_by(id: params[:id])

      return render_unauthorized("権限がありません") unless @member

      if @member.user_id.present? && @member.user_id != @current_user.id
        render_unauthorized("権限がありません")
      end
    end

    def find_or_create_family
      if params[:family_id].present?
        family = Family.find_by(id: params[:family_id])
        render json: { error: "ファミリーが見つかりません" }, status: :bad_request unless family
        family
      else
        Family.create!(name: params.dig(:family, :name))
      end
    end

    def member_params
      params.require(:member).permit(
        :name,
        likes_attributes: [:id, :name, :_destroy],
        dislikes_attributes: [:id, :name, :_destroy]
      )
    end
  end
end
