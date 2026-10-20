class TelegramWebhookController < ApplicationController
  skip_forgery_protection

  def create
    update = Telegram::Bot::Types::Update.new(params.permit!.to_h)
    service = TelegramBotService.new(bot_client)

    if update.message
      service.handle_message(update.message)
    elsif update.callback_query
      service.handle_callback(update.callback_query)
    end

    head :ok
  end

  private

  def bot_client
    @bot_client ||= Telegram::Bot::Client.new(ENV.fetch("TELEGRAM_BOT_TOKEN"))
  end
end
