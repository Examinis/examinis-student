class UsersController < ApplicationController
  before_action :authenticate_user!
  load_and_authorize_resource

  def index
    @users = @users.order(:last_nam, :first_name)
  end

  def show
  end
end
