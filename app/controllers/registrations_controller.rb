class RegistrationsController < ApplicationController
  allow_unauthenticated_access

  def new
    @user = User.new(role: params[:role] || "client")
  end

  def create
    @user = User.new(user_params)
    if @user.save
      setup_default_host_data(@user) if @user.host?
      start_new_session_for(@user)
      target_url = @user.client? ? client_root_path : panel_root_path
      redirect_to target_url, notice: "Hesabınız başarıyla oluşturuldu! Hoş geldiniz."
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def user_params
    params.require(:user).permit(:name, :email_address, :password, :password_confirmation, :role)
  end

  def setup_default_host_data(user)
    user.event_types.create!(
      name: "Birebir Görüşme",
      duration_minutes: 30,
      requires_approval: true,
      approval_window_hours: 24,
      slug: "gorusme",
      location: "Google Meet"
    )
    # Hafta içi standart çalışma saatleri (1: Pazartesi .. 5: Cuma)
    (1..5).each do |day|
      user.availability_rules.create!(
        day_of_week: day,
        start_time: "09:00",
        end_time: "17:00"
      )
    end
  rescue StandardError => e
    Rails.logger.warn("Varsayılan ev sahibi verisi oluşturulamadı: #{e.message}")
  end
end
