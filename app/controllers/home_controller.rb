class HomeController < ApplicationController
  allow_unauthenticated_access

  def index
    if authenticated?
      if current_user.client?
        redirect_to client_root_path
      else
        redirect_to panel_root_path
      end
    else
      redirect_to new_session_path
    end
  end
end
