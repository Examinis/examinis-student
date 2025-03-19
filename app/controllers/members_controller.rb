class MembersController < ApplicationController
  before_action :authenticate_user!
  load_and_authorize_resource class: "User", instance_name: "user"

  def index
    @users = User.all.order(:last_name, :first_name)
  end

  def show
    @user = User.find(params[:id])
  end

  def edit
    @user = User.find(params[:id])
  end

  def update
    @user = User.find(params[:id])
    if @user.update(user_params)
      redirect_to member_path(@user), notice: "Usuário atualizado com sucesso."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def user_params
    params.require(:user).permit(:first_name, :last_name, :email, :role)
  end
end
