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

ActiveRecord::Schema[8.1].define(version: 2026_07_12_000600) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"
  enable_extension "unaccent"

  create_table "accounts", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "discarded_at"
    t.integer "initial_balance", default: 0, null: false
    t.string "kind"
    t.string "name"
    t.datetime "updated_at", null: false
    t.uuid "wallet_id", null: false
    t.index ["wallet_id"], name: "index_accounts_on_wallet_id"
  end

  create_table "credit_balances", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.integer "closing_day"
    t.datetime "created_at", null: false
    t.integer "credit_limit"
    t.datetime "discarded_at"
    t.integer "due_day"
    t.string "name"
    t.datetime "updated_at", null: false
    t.uuid "wallet_id", null: false
    t.index ["wallet_id"], name: "index_credit_balances_on_wallet_id"
  end

  create_table "credit_cards", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.uuid "credit_balance_id", null: false
    t.datetime "discarded_at"
    t.string "last_digits"
    t.string "name"
    t.datetime "updated_at", null: false
    t.index ["credit_balance_id"], name: "index_credit_cards_on_credit_balance_id"
  end

  create_table "transactions", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.uuid "credit_card_id"
    t.string "description"
    t.datetime "discarded_at"
    t.boolean "draft", default: false, null: false
    t.string "kind"
    t.uuid "paid_credit_balance_id"
    t.datetime "settled_at"
    t.uuid "source_id", null: false
    t.string "source_type", null: false
    t.datetime "transaction_date"
    t.datetime "updated_at", null: false
    t.uuid "user_id", null: false
    t.integer "value"
    t.uuid "wallet_id", null: false
    t.index ["credit_card_id"], name: "index_transactions_on_credit_card_id"
    t.index ["paid_credit_balance_id"], name: "index_transactions_on_paid_credit_balance_id"
    t.index ["source_type", "source_id"], name: "index_transactions_on_source"
    t.index ["user_id"], name: "index_transactions_on_user_id"
    t.index ["wallet_id", "transaction_date"], name: "index_transactions_on_wallet_id_and_transaction_date"
    t.index ["wallet_id"], name: "index_transactions_on_wallet_id"
  end

  create_table "user_wallets", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.boolean "accepted", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "discarded_at"
    t.datetime "updated_at", null: false
    t.uuid "user_id", null: false
    t.uuid "wallet_id", null: false
    t.index ["user_id", "wallet_id", "discarded_at"], name: "index_user_wallets_on_user_id_and_wallet_id_and_discarded_at", unique: true
    t.index ["user_id"], name: "index_user_wallets_on_user_id"
    t.index ["wallet_id"], name: "index_user_wallets_on_wallet_id"
  end

  create_table "users", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "discarded_at"
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.uuid "main_user_wallet_id"
    t.string "name"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.datetime "updated_at", null: false
    t.index ["email", "discarded_at"], name: "index_users_on_email_and_discarded_at", unique: true
    t.index ["main_user_wallet_id"], name: "index_users_on_main_user_wallet_id"
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  create_table "versions", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at"
    t.string "event", null: false
    t.uuid "item_id", null: false
    t.string "item_type", null: false
    t.text "object"
    t.jsonb "object_changes"
    t.string "whodunnit"
    t.index ["item_type", "item_id"], name: "index_versions_on_item_type_and_item_id"
  end

  create_table "wallets", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "discarded_at"
    t.string "name"
    t.uuid "owner_id", null: false
    t.datetime "updated_at", null: false
    t.index ["owner_id"], name: "index_wallets_on_owner_id"
  end

  add_foreign_key "accounts", "wallets"
  add_foreign_key "credit_balances", "wallets"
  add_foreign_key "credit_cards", "credit_balances"
  add_foreign_key "transactions", "credit_balances", column: "paid_credit_balance_id"
  add_foreign_key "transactions", "credit_cards"
  add_foreign_key "transactions", "users"
  add_foreign_key "transactions", "wallets"
  add_foreign_key "user_wallets", "users"
  add_foreign_key "user_wallets", "wallets"
  add_foreign_key "users", "user_wallets", column: "main_user_wallet_id"
  add_foreign_key "wallets", "users", column: "owner_id"
end
