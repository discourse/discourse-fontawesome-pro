# frozen_string_literal: true

# name: discourse-fontawesome-pro
# about: Allows the use of Font Awesome Pro icons.
# meta_topic_id: 150871
# version: 0.1
# authors: Jeff Wong
# url: https://github.com/discourse/discourse-fontawesome-pro

enabled_site_setting :fontawesome_pro_icons_enabled

register_asset "stylesheets/common/fontawesome-pro.scss"

module ::DiscourseFontawesomePro
  PLUGIN_NAME = "discourse-fontawesome-pro"
end

require_relative "lib/discourse_fontawesome_pro/engine"

after_initialize do
  register_seedfu_fixtures(File.expand_path("db/fixtures", __dir__))

  register_problem_check(ProblemCheck::FontawesomeProIcons)
  register_svg_symbol_source(DiscourseFontawesomePro::Icons)
  register_svg_icon_source { DiscourseFontawesomePro::Icons.sprite_icons }

  add_to_serializer(:site, :fontawesome_pro_icons) { DiscourseFontawesomePro::Icons.replaceable }

  on(:site_setting_changed) do |name|
    if %i[fontawesome_pro_icons_enabled fontawesome_auth_token].include?(name)
      Jobs.enqueue(Jobs::DiscourseFontawesomePro::FetchIcons)
    end
  end
end
