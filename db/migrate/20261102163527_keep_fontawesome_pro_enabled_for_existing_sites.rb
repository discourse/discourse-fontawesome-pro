# frozen_string_literal: true

class KeepFontawesomeProEnabledForExistingSites < ActiveRecord::Migration[8.1]
  def up
    return if !Migration::Helpers.existing_site?
    return if GlobalSetting.try(:fontawesome_auth_token).blank?

    # 5 is the bool data_type
    execute <<~SQL
      INSERT INTO site_settings(name, data_type, value, created_at, updated_at)
      VALUES('fontawesome_pro_icons_enabled', 5, 't', NOW(), NOW())
      ON CONFLICT (name) DO NOTHING
    SQL
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
