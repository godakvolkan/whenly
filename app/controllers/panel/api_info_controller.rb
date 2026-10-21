class Panel::ApiInfoController < Panel::BaseController
  def show
    @api_token = current_user.api_token
    unless @api_token
      current_user.regenerate_api_token!
      @api_token = current_user.reload.api_token
    end
  end

  def regenerate_token
    current_user.regenerate_api_token!
    redirect_to panel_api_info_path, notice: "API anahtarı yenilendi."
  end
end
