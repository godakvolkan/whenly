require "telegram/bot"

class TelegramWebhookController < ApplicationController
  allow_unauthenticated_access
  skip_forgery_protection

  def create
    token = ENV["TELEGRAM_BOT_TOKEN"].presence
    return head :ok unless token

    update = Telegram::Bot::Types::Update.new(params.permit!.to_h)
    service = TelegramBotService.new(bot_client)

    if update.message
      service.handle_message(update.message)
    elsif update.callback_query
      service.handle_callback(update.callback_query)
    end

    head :ok
  rescue StandardError => e
    Rails.logger.error("[TelegramWebhook] Error: #{e.class} - #{e.message}\n#{e.backtrace&.first(5)&.join("\n")}")
    head :ok unless performed?
  end

  private

  def bot_client
    @bot_client ||= Telegram::Bot::Client.new(ENV.fetch("TELEGRAM_BOT_TOKEN"))
  end
end
