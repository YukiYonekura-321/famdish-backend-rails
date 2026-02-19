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

ActiveRecord::Schema[8.0].define(version: 2026_02_19_224427) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "dislikes", force: :cascade do |t|
    t.bigint "member_id", null: false
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["member_id"], name: "index_dislikes_on_member_id"
  end

  create_table "families", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "today_cook_id"
  end

  create_table "goods", force: :cascade do |t|
    t.integer "user_id"
    t.integer "menu_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "suggestion_id"
  end

  create_table "invitations", force: :cascade do |t|
    t.string "token", null: false
    t.bigint "family_id", null: false
    t.boolean "used", default: false, null: false
    t.datetime "expires_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["family_id"], name: "index_invitations_on_family_id"
    t.index ["token"], name: "index_invitations_on_token", unique: true
  end

  create_table "likes", force: :cascade do |t|
    t.bigint "member_id", null: false
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["member_id"], name: "index_likes_on_member_id"
  end

  create_table "members", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "family_id", null: false
    t.bigint "user_id"
    t.index ["family_id"], name: "index_members_on_family_id"
    t.index ["user_id"], name: "index_members_on_user_id"
  end

  create_table "menus", force: :cascade do |t|
    t.string "name"
    t.string "favorite"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "member_id", null: false
    t.index ["member_id"], name: "index_menus_on_member_id"
  end

  create_table "recipes", force: :cascade do |t|
    t.string "dish_name", null: false
    t.bigint "proposer"
    t.integer "servings"
    t.json "missing_ingredients"
    t.integer "cooking_time"
    t.json "steps"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "stocks", force: :cascade do |t|
    t.bigint "family_id", null: false
    t.string "name", null: false
    t.decimal "quantity"
    t.string "unit"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["family_id"], name: "index_stocks_on_family_id"
  end

  create_table "suggestions", force: :cascade do |t|
    t.bigint "family_id"
    t.json "requests"
    t.text "ai_raw_json"
    t.string "chosen_option"
    t.text "feedback"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "proposer", null: false
  end

  create_table "users", force: :cascade do |t|
    t.string "firebase_uid"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "family_id"
    t.index ["family_id"], name: "index_users_on_family_id"
  end

  add_foreign_key "dislikes", "members"
  add_foreign_key "families", "members", column: "today_cook_id"
  add_foreign_key "invitations", "families"
  add_foreign_key "likes", "members"
  add_foreign_key "members", "families"
  add_foreign_key "members", "users"
  add_foreign_key "menus", "members"
  add_foreign_key "recipes", "members", column: "proposer"
  add_foreign_key "stocks", "families"
  add_foreign_key "suggestions", "members", column: "proposer"
  add_foreign_key "users", "families"
end
