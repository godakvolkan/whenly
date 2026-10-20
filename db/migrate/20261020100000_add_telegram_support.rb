class AddTelegramSupport < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :telegram_chat_id, :bigint
    add_index :users, :telegram_chat_id, unique: true

    create_table :telegram_sessions do |t|
      t.bigint :chat_id, null: false
      t.string :state, default: "idle", null: false
      t.jsonb :data, default: {}
      t.timestamps
    end
    add_index :telegram_sessions, :chat_id, unique: true
  end
end
