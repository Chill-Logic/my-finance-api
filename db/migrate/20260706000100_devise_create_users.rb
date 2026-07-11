# frozen_string_literal: true

class DeviseCreateUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :users, id: :uuid do |t|
      ## Database authenticatable
      t.string :email,              null: false, default: ""
      t.string :encrypted_password, null: false, default: ""

      ## Recoverable
      t.string   :reset_password_token
      t.datetime :reset_password_sent_at

      ## Custom parameters
      t.string :name

      t.datetime :discarded_at
      t.timestamps null: false
    end

    add_index :users, [:email, :discarded_at], unique: true
    add_index :users, :reset_password_token,   unique: true
  end
end
