module Api
  module V1
    class BaseController < ActionController::API
      before_action :authenticate_api!

      private

      def authenticate_api!
        token = request.headers["Authorization"]&.remove("Bearer ")
        @current_user = User.find_by(api_token: token) if token.present?
        render json: { error: "Unauthorized" }, status: :unauthorized unless @current_user
      end

      def current_user
        @current_user
      end
    end
  end
end
