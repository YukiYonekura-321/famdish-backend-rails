module Api
  class ContactsController < ApplicationController
    skip_before_action :authenticate_user!, only: [:create]
    wrap_parameters false

    # POST /api/contacts
    def create
      contact = Contact.new(contact_params)

      if contact.save
        render json: { message: "お問い合わせを受け付けました" }, status: :created
      else
        render json: { errors: contact.errors.full_messages }, status: :unprocessable_entity
      end
    end

    private

    def contact_params
      params.require(:contact).permit(:name, :email, :subject, :message)
    end
  end
end
