module Api
  class ContactsController < ApplicationController
    skip_before_action :authenticate_user!, only: [ :create ]

    # POST /api/contacts
    def create
      Rails.logger.info "[ContactsController#create] Params: #{params.inspect}"

      contact = Contact.new(contact_params)

      if contact.save
        render json: { message: "お問い合わせを受け付けました" }, status: :created
      else
        Rails.logger.error "[ContactsController#create] Validation errors: #{contact.errors.full_messages}"
        render json: { errors: contact.errors.full_messages }, status: :unprocessable_entity
      end
    end

    private

    def contact_params
      params.require(:contact).permit(:name, :email, :subject, :message)
    end
  end
end
