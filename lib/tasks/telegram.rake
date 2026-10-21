require "telegram/bot"

namespace :telegram do
  desc "Start Telegram bot in polling mode"
  task bot: :environment do
    $stdout.sync = true
    token = ENV.fetch("TELEGRAM_BOT_TOKEN")
    puts "Starting Telegram bot polling..."

    Telegram::Bot::Client.run(token) do |bot|
      service = TelegramBotService.new(bot)
      puts "Bot is running. Listening for messages..."

      bot.listen do |update|
        puts "Update received: #{update.class.name}"
        case update
        when Telegram::Bot::Types::Message
          puts "Message from #{update.chat.id}: #{update.text}"
          service.handle_message(update)
        when Telegram::Bot::Types::CallbackQuery
          puts "Callback: #{update.data}"
          service.handle_callback(update)
        end
      rescue => e
        puts "ERROR: #{e.class}: #{e.message}"
        puts e.backtrace.first(5).join("\n")
      end
    end
  end

  desc "Set Telegram webhook URL"
  task :set_webhook, [:url] => :environment do |_t, args|
    token = ENV.fetch("TELEGRAM_BOT_TOKEN")
    url = args[:url] || "#{ENV.fetch('APP_URL')}/telegram/webhook"
    client = Telegram::Bot::Client.new(token)
    result = client.api.set_webhook(url: url)
    puts result.inspect
  end

  desc "Remove Telegram webhook"
  task remove_webhook: :environment do
    token = ENV.fetch("TELEGRAM_BOT_TOKEN")
    client = Telegram::Bot::Client.new(token)
    result = client.api.delete_webhook
    puts result.inspect
  end
end
