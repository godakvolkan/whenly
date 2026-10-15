# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_10_14_201445) do
  create_table "availability_rules", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "day_of_week", null: false
    t.time "start_time", null: false
    t.time "end_time", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id", "day_of_week"], name: "index_availability_rules_on_user_id_and_day_of_week", unique: true
    t.index ["user_id"], name: "index_availability_rules_on_user_id"
  end

  create_table "bookings", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "event_type_id", null: false
    t.string "invitee_name", null: false
    t.string "invitee_email", null: false
    t.datetime "starts_at", null: false
    t.datetime "ends_at", null: false
    t.string "status", default: "pending", null: false
    t.datetime "approval_deadline_at"
    t.string "token", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["event_type_id"], name: "index_bookings_on_event_type_id"
    t.index ["token"], name: "index_bookings_on_token", unique: true
    t.index ["user_id", "starts_at"], name: "idx_bookings_no_double", unique: true, where: "status IN ('pending', 'confirmed')"
    t.index ["user_id"], name: "index_bookings_on_user_id"
  end

  create_table "event_types", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "name", null: false
    t.integer "duration_minutes", default: 30, null: false
    t.boolean "requires_approval", default: true, null: false
    t.integer "approval_window_hours", default: 24
    t.string "slug", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id", "slug"], name: "index_event_types_on_user_id_and_slug", unique: true
    t.index ["user_id"], name: "index_event_types_on_user_id"
  end

  create_table "sessions", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "ip_address"
    t.string "user_agent"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "name", null: false
    t.string "email_address", null: false
    t.string "password_digest", null: false
    t.string "slug", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
    t.index ["slug"], name: "index_users_on_slug", unique: true
  end

  add_foreign_key "availability_rules", "users"
  add_foreign_key "bookings", "event_types"
  add_foreign_key "bookings", "users"
  add_foreign_key "event_types", "users"
  add_foreign_key "sessions", "users"
end
