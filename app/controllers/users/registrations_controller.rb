# frozen_string_literal: true

class Users::RegistrationsController < Devise::RegistrationsController
  before_action :configure_sign_up_params, only: [ :create ]
  before_action :configure_account_update_params, only: [ :update ]

  # GET /resource/sign_up
  def new
    @user = User.new
    # Ensure that the user has at least one contact to fill in
    @user.contacts.build
  end

  # POST /resource
  # def create
  #   super
  # end

  # GET /resource/edit
  def edit
    @user = current_user
    # Ensure that the user has at least one contact to edit
    @user.contacts.build if @user.contacts.empty?
  end

  # PUT /resource
  def update
    @user = current_user
    # If the update is successful, redirect to the user profile page
    if @user.update(user_params)
      redirect_to user_path(@user), notice: "Perfil atualizado com sucesso!"
    end
  end

  # DELETE /resource
  # def destroy
  #   super
  # end

  # GET /resource/cancel
  # Forces the session data which is usually expired after sign
  # in to be expired now. This is useful if the user wants to
  # cancel oauth signing in/up in the middle of the process,
  # removing all OAuth session data.
  # def cancel
  #   super
  # end

  protected

  # If you have extra params to permit, append them to the sanitizer.
  def configure_sign_up_params
    devise_parameter_sanitizer.permit(:sign_up, keys: [ :first_name, :last_name,
      contacts_attributes: [ :id, :contact_type, :value, :_destroy ] ])
  end

  # If you have extra params to permit, append them to the sanitizer.
  def configure_account_update_params
    devise_parameter_sanitizer.permit(:account_update, keys: [ :first_name, :last_name,
      contacts_attributes: [ :id, :contact_type, :value, :_destroy ] ])
  end

  # The path used after sign up.
  # def after_sign_up_path_for(resource)
  #   super(resource)
  # end

  # The path used after sign up for inactive accounts.
  # def after_inactive_sign_up_path_for(resource)
  #   super(resource)
  # end

  private

  def user_params
    params.require(:user).permit(:first_name, :last_name,
      # Nested attributes for contacts
      contacts_attributes: [ :id, :contact_type, :value, :_destroy ])
  end
end
