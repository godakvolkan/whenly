module Api
  module V1
    class EventTypesController < BaseController
      def index
        render json: current_user.event_types.map { |et| serialize(et) }
      end

      def show
        et = current_user.event_types.find(params[:id])
        render json: serialize(et)
      end

      def available_slots
        et = current_user.event_types.find(params[:id])
        date = Date.parse(params[:date])
        slots = SlotFinder.new(current_user, et, date).available_slots

        render json: slots.map { |s|
          { starts_at: s[:starts_at].iso8601, ends_at: s[:ends_at].iso8601 }
        }
      end

      private

      def serialize(et)
        {
          id: et.id,
          name: et.name,
          slug: et.slug,
          duration_minutes: et.duration_minutes,
          requires_approval: et.requires_approval,
          location: et.location
        }
      end
    end
  end
end
