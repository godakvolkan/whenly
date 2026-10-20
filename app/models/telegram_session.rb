class TelegramSession < ApplicationRecord
  STATES = %w[idle select_host select_event_type select_date select_slot enter_name enter_email].freeze

  validates :chat_id, presence: true, uniqueness: true
  validates :state, inclusion: { in: STATES }

  def self.for(chat_id)
    find_or_create_by!(chat_id: chat_id)
  end

  def reset!
    update!(state: "idle", data: {})
  end

  def set(key, value)
    self.data = data.merge(key.to_s => value)
    save!
  end

  def get(key)
    data[key.to_s]
  end

  def transition_to!(new_state)
    update!(state: new_state)
  end
end
