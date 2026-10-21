class Panel::EventTypesController < Panel::BaseController
  before_action :set_event_type, only: [:edit, :update, :destroy]

  def index
    @event_types = current_user.event_types.order(created_at: :desc)
  end

  def new
    @event_type = current_user.event_types.new(
      duration_minutes: 30,
      requires_approval: true,
      approval_window_hours: 24
    )
  end

  def create
    @event_type = current_user.event_types.new(event_type_params)

    if @event_type.save
      redirect_to panel_event_types_path, notice: "Randevu türü başarıyla oluşturuldu."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @event_type.update(event_type_params)
      redirect_to panel_event_types_path, notice: "Randevu türü güncellendi."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @event_type.destroy
    redirect_to panel_event_types_path, notice: "Randevu türü silindi."
  end

  private

  def set_event_type
    @event_type = current_user.event_types.find(params[:id])
  end

  def event_type_params
    params.require(:event_type).permit(:name, :duration_minutes, :requires_approval, :approval_window_hours, :slug, :location)
  end
end
