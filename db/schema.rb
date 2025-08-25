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

ActiveRecord::Schema[8.0].define(version: 2025_08_25_061906) do
  create_table "ingredients", force: :cascade do |t|
    t.string "name", null: false
    t.integer "product_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_ingredients_on_name"
    t.index ["product_id", "created_at"], name: "index_ingredients_on_product_id_and_created_at"
    t.index ["product_id"], name: "index_ingredients_on_product_id"
  end

  create_table "prepare_ingredients", force: :cascade do |t|
    t.integer "prepare_id", null: false
    t.string "ingredient_name", null: false
    t.boolean "checked", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["prepare_id", "ingredient_name"], name: "index_prepare_ingredients_on_prepare_id_and_ingredient_name"
    t.index ["prepare_id"], name: "index_prepare_ingredients_on_prepare_id"
  end

  create_table "prepares", force: :cascade do |t|
    t.integer "product_id", null: false
    t.date "prepare_date", null: false
    t.string "prepare_id", null: false
    t.integer "status", default: 0
    t.integer "checked_by_id"
    t.integer "created_by_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["checked_by_id"], name: "index_prepares_on_checked_by_id"
    t.index ["created_by_id"], name: "index_prepares_on_created_by_id"
    t.index ["prepare_id"], name: "index_prepares_on_prepare_id", unique: true
    t.index ["product_id", "prepare_date"], name: "index_prepares_on_product_id_and_prepare_date", unique: true
    t.index ["product_id"], name: "index_prepares_on_product_id"
  end

  create_table "products", force: :cascade do |t|
    t.string "name", null: false
    t.integer "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_products_on_name"
    t.index ["user_id", "created_at"], name: "index_products_on_user_id_and_created_at"
    t.index ["user_id"], name: "index_products_on_user_id"
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
    t.string "email_address", null: false
    t.string "password_digest", null: false
    t.integer "role", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
  end

  add_foreign_key "ingredients", "products"
  add_foreign_key "prepare_ingredients", "prepares"
  add_foreign_key "prepares", "products"
  add_foreign_key "prepares", "users", column: "checked_by_id"
  add_foreign_key "prepares", "users", column: "created_by_id"
  add_foreign_key "products", "users"
  add_foreign_key "sessions", "users"
end
