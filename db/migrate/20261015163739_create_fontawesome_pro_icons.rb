# frozen_string_literal: true
class CreateFontawesomeProIcons < ActiveRecord::Migration[8.1]
  def change
    create_table :fontawesome_pro_icons do |t|
      t.string :name, null: false
      t.text :symbol, null: false
      t.string :version, null: false
      t.timestamps
    end

    add_index :fontawesome_pro_icons, :name, unique: true
  end
end
