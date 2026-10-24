class PublicProfilesController < ApplicationController
  allow_unauthenticated_access
  rescue_from ActiveRecord::RecordNotFound, with: :profile_not_found

  def show
    @user = User.find_by!(slug: params[:slug])
    @event_types = @user.event_types.order(:created_at)

    # Eğer kullanıcının sadece 1 randevu türü varsa ve doğrudan oraya yönlendirmek istenirse
    # veya profil görünümü olarak tüm randevu türlerini listelemek
    respond_to do |format|
      format.html
      format.json { render json: { user: @user.as_json(only: [:id, :name, :slug]), event_types: @event_types } }
    end
  end

  private

  def profile_not_found
    render "public_bookings/not_found", status: :not_found
  end
end
