module Api
  class MembersController < ApplicationController
    before_action :authenticate_user!

    def index
      members = Member.all
      render json: members.as_json(include: [:likes, :dislikes])
    end

    def show
      member = Member.find(params[:id])
      render json: member.as_json(include: [:likes, :dislikes])
    rescue ActiveRecord::RecordNotFound
      render_unauthorized("メンバーが見つかりません")
    end

    def create
      ActiveRecord::Base.transaction do
        # Family を作成
        family = @current_user.family || Family.create!(name: params[:family][:name], user: @current_user)

        # Member を作成
        member = Member.new(member_params)
        member.family = family  # familyを紐付け
        member.save!

        render json: member.as_json(include: [:likes, :dislikes, family: { only: [:id, :name] }]), status: :created
      rescue ActiveRecord::RecordInvalid => e
        render json: { errors: e.record.errors.full_messages }, status: :unprocessable_entity
      end
    end

    def update
      # Rails.logger.info "params[:id] = #{params[:id].inspect}"
      member = Member.find(params[:id])
      # Rails.logger.info "Found member: #{member.id}"
      # 既存の likes/dislikes と 送られてきた likes/dislikes を比較して、差分を更新
      # if member.likes.map(&:name).sort != (member_params[:likes_attributes] || []).map { |l| l[:name] }.sort
      #   member.likes.destroy_all
      # end
      # if member.dislikes.map(&:name).sort != (member_params[:dislikes_attributes] || []).map { |d| d[:name] }.sort
      #   member.dislikes.destroy_all
      # end
      # Rails.logger.info "member_params = #{member_params.inspect}"
      # Rails.logger.info "member.likes = #{member.likes.inspect}"
      # Rails.logger.info "member.dislikes = #{member.dislikes.inspect}"
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

    private

    def member_params
      params.require(:member).permit(
        :name,
        likes_attributes: [:id, :name, :_destroy],
        dislikes_attributes: [:id, :name, :_destroy]
      )
    end

    # def member_params
    #   params.require(:member).permit(:name, :likes, :dislikes)
    # end
  end
end
