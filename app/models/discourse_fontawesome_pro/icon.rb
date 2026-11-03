# frozen_string_literal: true

module DiscourseFontawesomePro
  class Icon < ActiveRecord::Base
    self.table_name = "fontawesome_pro_icons"
  end
end

# == Schema Information
#
# Table name: fontawesome_pro_icons
#
#  id         :bigint           not null, primary key
#  name       :string           not null
#  symbol     :text             not null
#  version    :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_fontawesome_pro_icons_on_name  (name) UNIQUE
#
