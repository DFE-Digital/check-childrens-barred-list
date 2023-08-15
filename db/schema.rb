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

ActiveRecord::Schema[7.0].define(version: 2023_08_15_100506) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"
  enable_extension "unaccent"

  create_table "childrens_barred_list_entries", force: :cascade do |t|
    t.string "trn"
    t.string "first_names", null: false
    t.string "last_name", null: false
    t.date "date_of_birth", null: false
    t.string "national_insurance_number"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["first_names", "last_name", "date_of_birth"], name: "index_childrens_barred_list_entries_on_names_and_dob", unique: true
  end

  create_table "dsi_users", force: :cascade do |t|
    t.string "email", null: false
    t.string "first_name"
    t.string "last_name"
    t.string "uid", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_dsi_users_on_email", unique: true
  end

  create_table "feature_flags_features", force: :cascade do |t|
    t.string "name", null: false
    t.boolean "active", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_feature_flags_features_on_name", unique: true
  end

end
