# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20171031094443) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"
  enable_extension "uuid-ossp"

  create_table "deputies", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.string "user_email", null: false
    t.string "deputy",     null: false
    t.index ["deputy"], name: "index_deputies_on_deputy", using: :btree
  end

  create_table "permissions", force: :cascade do |t|
    t.string   "permitted",       null: false
    t.string   "permission_type", null: false
    t.string   "accessible_type", null: false
    t.uuid     "accessible_id",   null: false
    t.datetime "created_at",      null: false
    t.datetime "updated_at",      null: false
    t.index ["accessible_type", "accessible_id"], name: "index_permissions_on_accessible_type_and_accessible_id", using: :btree
    t.index ["permitted", "permission_type", "accessible_id", "accessible_type"], name: "index_permissions_on_various", unique: true, using: :btree
    t.index ["permitted"], name: "index_permissions_on_permitted", using: :btree
  end

  create_table "stamp_materials", force: :cascade do |t|
    t.uuid     "material_uuid", null: false
    t.uuid     "stamp_id",      null: false
    t.datetime "created_at",    null: false
    t.datetime "updated_at",    null: false
    t.index ["material_uuid", "stamp_id"], name: "index_stamp_materials_on_material_uuid_and_stamp_id", unique: true, using: :btree
    t.index ["material_uuid"], name: "index_stamp_materials_on_material_uuid", using: :btree
    t.index ["stamp_id"], name: "index_stamp_materials_on_stamp_id", using: :btree
  end

  create_table "stamps", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.string   "name",           null: false
    t.string   "owner_id",       null: false
    t.datetime "created_at",     null: false
    t.datetime "updated_at",     null: false
    t.datetime "deactivated_at"
    t.index ["name"], name: "index_stamps_on_name", using: :btree
  end

  add_foreign_key "stamp_materials", "stamps"
end
