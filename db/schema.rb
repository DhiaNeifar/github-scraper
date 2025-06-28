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

ActiveRecord::Schema[8.0].define(version: 2025_06_28_005606) do
  create_table "organizations", force: :cascade do |t|
    t.string "name", null: false
    t.string "url", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_organizations_on_name", unique: true
  end

  create_table "pull_requests", force: :cascade do |t|
    t.integer "number", null: false
    t.string "url", null: false
    t.string "title"
    t.string "status"
    t.datetime "last_update_at"
    t.datetime "closed_at"
    t.datetime "merged_at"
    t.integer "additions"
    t.integer "deletions"
    t.integer "changed_files"
    t.integer "number_commits"
    t.integer "repository_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id"
    t.index ["repository_id", "number"], name: "index_pull_requests_on_repository_id_and_number", unique: true
    t.index ["repository_id"], name: "index_pull_requests_on_repository_id"
    t.index ["user_id"], name: "index_pull_requests_on_user_id"
  end

  create_table "repositories", force: :cascade do |t|
    t.string "name", null: false
    t.string "url", null: false
    t.boolean "is_public", default: true, null: false
    t.boolean "is_archived", default: false, null: false
    t.integer "organization_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["organization_id", "name"], name: "index_repositories_on_organization_id_and_name", unique: true
    t.index ["organization_id"], name: "index_repositories_on_organization_id"
  end

  create_table "reviews", force: :cascade do |t|
    t.string "state", null: false
    t.datetime "submitted_at", null: false
    t.integer "pull_request_id", null: false
    t.integer "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["pull_request_id"], name: "index_reviews_on_pull_request_id"
    t.index ["user_id"], name: "index_reviews_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "name", null: false
    t.string "url", null: false
    t.string "nickname", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["url"], name: "index_users_on_url", unique: true
  end

  add_foreign_key "pull_requests", "repositories"
  add_foreign_key "pull_requests", "users"
  add_foreign_key "repositories", "organizations"
  add_foreign_key "reviews", "pull_requests"
  add_foreign_key "reviews", "users"
end
