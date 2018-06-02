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

ActiveRecord::Schema.define(version: 20180602081528) do

  create_table "buglists", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string "err_msg"
    t.string "mstep"
    t.string "fstep"
    t.string "user_msg"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "emds", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.bigint "gusigun_id"
    t.string "towncode"
    t.string "emdcode"
    t.string "emdname"
    t.string "findlist"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["gusigun_id"], name: "index_emds_on_gusigun_id"
  end

  create_table "gusiguns", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.bigint "sido_id"
    t.string "wiwid"
    t.string "wiwtypecode"
    t.string "towncode"
    t.string "townname"
    t.string "guname"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["sido_id"], name: "index_gusiguns_on_sido_id"
  end

  create_table "sidos", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string "wiwid"
    t.string "wiwname"
    t.string "findlist"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "users", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer "chat_room"
    t.string "user_key"
    t.string "sido"
    t.string "sigun"
    t.string "gu"
    t.string "emd"
    t.string "sido_code"
    t.string "gusigun_code"
    t.string "emd_code"
    t.string "url"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_foreign_key "emds", "gusiguns"
  add_foreign_key "gusiguns", "sidos"
end
