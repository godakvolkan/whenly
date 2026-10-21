module Api
  module V1
    class BookingsController < BaseController
      def index
        bookings = current_user.bookings.order(starts_at: :desc)
        bookings = bookings.where(status: params[:status]) if params[:status].present?
        bookings = bookings.limit(params[:limit] || 25)
        render json: bookings.map { |b| serialize_booking(b) }
      end

      def show
        booking = current_user.bookings.find(params[:id])
        render json: serialize_booking(booking)
      end

      def create
        et = current_user.event_types.find(params[:event_type_id])
        result = Bookings::Create.new(
          user: current_user,
          event_type: et,
          params: {
            invitee_name: params[:invitee_name],
            invitee_email: params[:invitee_email],
            starts_at: params[:starts_at]
          }
        ).call

        if result.success?
          render json: serialize_booking(result.booking), status: :created
        else
          render json: { error: result.error }, status: :unprocessable_entity
        end
      end

      def confirm
        booking = current_user.bookings.find(params[:id])
        booking.confirm!
        BookingMailer.booking_confirmed(booking).deliver_later rescue nil
        render json: serialize_booking(booking)
      rescue Booking::InvalidTransition => e
        render json: { error: e.message }, status: :unprocessable_entity
      end

      def decline
        booking = current_user.bookings.find(params[:id])
        booking.decline!
        BookingMailer.booking_declined(booking).deliver_later rescue nil
        render json: serialize_booking(booking)
      rescue Booking::InvalidTransition => e
        render json: { error: e.message }, status: :unprocessable_entity
      end

      def cancel
        booking = current_user.bookings.find(params[:id])
        booking.cancel!
        render json: serialize_booking(booking)
      rescue Booking::InvalidTransition => e
        render json: { error: e.message }, status: :unprocessable_entity
      end

      def ics
        booking = current_user.bookings.find(params[:id])
        send_data IcsGenerator.call(booking),
                  filename: "booking_#{booking.token}.ics",
                  type: "text/calendar"
      end

      private

      def serialize_booking(b)
        {
          id: b.id,
          invitee_name: b.invitee_name,
          invitee_email: b.invitee_email,
          event_type: b.event_type.name,
          status: b.status,
          starts_at: b.starts_at.iso8601,
          ends_at: b.ends_at.iso8601,
          location: b.event_type.location,
          token: b.token,
          created_at: b.created_at.iso8601
        }
      end
    end
  end
end
