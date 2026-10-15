class Panel::AvailabilityRulesController < Panel::BaseController
  def index
    @rules = current_user.availability_rules.index_by(&:day_of_week)
  end

  def create
    rules_params = params[:rules] || {}
    errors = []

    ActiveRecord::Base.transaction do
      (1..7).each do |day|
        day_params = rules_params[day.to_s] || {}
        rule = current_user.availability_rules.find_or_initialize_by(day_of_week: day)

        if day_params[:active] == "1" || day_params[:enabled] == "1"
          rule.start_time = day_params[:start_time].presence || "09:00"
          rule.end_time = day_params[:end_time].presence || "17:00"
          unless rule.save
            errors << "#{rule.day_name}: #{rule.errors.full_messages.join(', ')}"
          end
        elsif rule.persisted?
          rule.destroy
        end
      end

      raise ActiveRecord::Rollback if errors.any?
    end

    if errors.empty?
      redirect_to panel_availability_rules_path, notice: "Müsaitlik saatleri başarıyla güncellendi."
    else
      flash.now[:alert] = "Bazı kurallar kaydedilemedi: #{errors.join('; ')}"
      @rules = current_user.availability_rules.index_by(&:day_of_week)
      render :index, status: :unprocessable_entity
    end
  end
end
