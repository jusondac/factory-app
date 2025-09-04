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

ActiveRecord::Schema[8.0].define(version: 2025_08_31_054312) do
  create_table "ingredients", force: :cascade do |t|
    t.string "name", null: false
    t.integer "product_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_ingredients_on_name"
    t.index ["product_id", "created_at"], name: "index_ingredients_on_product_id_and_created_at"
    t.index ["product_id"], name: "index_ingredients_on_product_id"
  end

  create_table "machine_checkings", force: :cascade do |t|
    t.integer "machine_id", null: false
    t.string "checking_name"
    t.integer "checking_type"
    t.text "checking_value"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["machine_id"], name: "index_machine_checkings_on_machine_id"
  end

  create_table "machines", force: :cascade do |t|
    t.string "name"
    t.string "serial_number"
    t.integer "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "allocation"
    t.integer "line"
  end

  create_table "package_machine_checks", force: :cascade do |t|
    t.integer "package_id", null: false
    t.integer "machine_checking_id", null: false
    t.string "question"
    t.text "answer"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["machine_checking_id"], name: "index_package_machine_checks_on_machine_checking_id"
    t.index ["package_id"], name: "index_package_machine_checks_on_package_id"
  end

  create_table "packages", force: :cascade do |t|
    t.date "package_date", null: false
    t.string "package_id", null: false
    t.integer "status", default: 0, null: false
    t.integer "unit_batch_id", null: false
    t.integer "machine_id"
    t.integer "waste_quantity", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "machine_check", default: false
    t.index ["machine_id"], name: "index_packages_on_machine_id"
    t.index ["package_date"], name: "index_packages_on_package_date"
    t.index ["package_id"], name: "index_packages_on_package_id", unique: true
    t.index ["unit_batch_id"], name: "index_packages_on_unit_batch_id"
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
    t.date "prepare_date", null: false
    t.string "prepare_id", null: false
    t.integer "status", default: 0
    t.integer "checked_by_id"
    t.integer "created_by_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "unit_batch_id", null: false
    t.integer "prepare_ingredients_count", default: 0
    t.integer "checked_ingredients_count", default: 0
    t.string "notes"
    t.index ["checked_by_id"], name: "index_prepares_on_checked_by_id"
    t.index ["created_by_id"], name: "index_prepares_on_created_by_id"
    t.index ["prepare_id"], name: "index_prepares_on_prepare_id", unique: true
    t.index ["unit_batch_id"], name: "index_prepares_on_unit_batch_id"
  end

  create_table "produce_machine_checks", force: :cascade do |t|
    t.integer "produce_id", null: false
    t.integer "machine_checking_id", null: false
    t.string "question"
    t.text "answer"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["machine_checking_id"], name: "index_produce_machine_checks_on_machine_checking_id"
    t.index ["produce_id"], name: "index_produce_machine_checks_on_produce_id"
  end

  create_table "produces", force: :cascade do |t|
    t.date "product_date", null: false
    t.string "product_id", null: false
    t.integer "status", default: 0, null: false
    t.integer "unit_batch_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "machine_id"
    t.boolean "machine_check", default: false
    t.index ["machine_id"], name: "index_produces_on_machine_id"
    t.index ["product_date"], name: "index_produces_on_product_date"
    t.index ["product_id"], name: "index_produces_on_product_id", unique: true
    t.index ["unit_batch_id"], name: "index_produces_on_unit_batch_id", unique: true
  end

  create_table "products", force: :cascade do |t|
    t.string "name", null: false
    t.integer "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "product_code"
    t.integer "period_year"
    t.integer "period_month"
    t.integer "period_week"
    t.integer "period_day"
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

  create_table "unit_batches", force: :cascade do |t|
    t.string "unit_id"
    t.integer "product_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "status", default: 0, null: false
    t.integer "quantity"
    t.integer "package_type"
    t.integer "shift"
    t.string "batch_code"
    t.integer "waste_quantity"
    t.datetime "expiry_date"
    t.index ["product_id"], name: "index_unit_batches_on_product_id"
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
  add_foreign_key "machine_checkings", "machines"
  add_foreign_key "package_machine_checks", "machine_checkings"
  add_foreign_key "package_machine_checks", "packages"
  add_foreign_key "packages", "machines"
  add_foreign_key "packages", "unit_batches"
  add_foreign_key "prepare_ingredients", "prepares"
  add_foreign_key "prepares", "unit_batches"
  add_foreign_key "prepares", "users", column: "checked_by_id"
  add_foreign_key "prepares", "users", column: "created_by_id"
  add_foreign_key "produce_machine_checks", "machine_checkings"
  add_foreign_key "produce_machine_checks", "produces"
  add_foreign_key "produces", "machines"
  add_foreign_key "produces", "unit_batches"
  add_foreign_key "products", "users"
  add_foreign_key "sessions", "users"
  add_foreign_key "unit_batches", "products"
end
