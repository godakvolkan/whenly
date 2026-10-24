class Panel::ProfileController < Panel::BaseController
  def edit
    @user = current_user
  end

  def update
    @user = current_user

    filtered_params = user_params
    if filtered_params[:password].blank? && filtered_params[:password_confirmation].blank?
      filtered_params = filtered_params.except(:password, :password_confirmation)
    end

    if @user.update(filtered_params)
      redirect_to edit_panel_profile_path, notice: "Profil ve hesap bilgileriniz başarıyla güncellendi."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def user_params
    params.require(:user).permit(:name, :slug, :password, :password_confirmation)
  end
end
