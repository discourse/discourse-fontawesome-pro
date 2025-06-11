# frozen_string_literal: true

# name: discourse-fontawesome-pro
# about: Allows the use of Font Awesome Pro icons.
# meta_topic_id: 150871
# version: 0.1
# authors: Jeff Wong
# url: https://github.com/discourse/discourse-fontawesome-pro

enabled_site_setting :fontawesome_pro_icons_enabled

register_asset "stylesheets/common/fontawesome-pro.scss"

require File.expand_path("lib/register_icons.rb", __dir__)

after_initialize do
  prefix_mapping = {
    "brands" => "fab",
    "light" => "fal",
    "regular" => "far",
    "duotone" => "fad",
    "solid" => "fas",
  }
  sprite_source =
    "#{Rails.root}/plugins/discourse-fontawesome-pro/fontawesome-workspace/node_modules/@fortawesome/fontawesome-pro/sprites"
  sprite_dest = "#{Rails.root}/vendor/assets/svg-icons/fontawesome-pro"
  FileUtils.mkdir_p(sprite_dest) unless Dir.exist?(sprite_dest)
  prefix_mapping.each do |style, prefix|
    fsource = "#{sprite_source}/#{style}.svg"
    fname = "#{sprite_dest}/#{style}-pro.svg"
    next unless File.file?(fsource)

    File.open(fsource) do |source_file|
      contents = source_file.read
      contents.gsub!(/<symbol id="(?<id>.*)"/, "<symbol id=\"#{prefix}-\\k<id>\"")
      File.open(fname, "w+") { |f| f.write(contents) }
    end
  end

  %w[fal far fad fas].each do |style|
    RegisterIcons.icon_replacements.each { |icon| register_svg_icon "#{style}-#{icon}" }
  end
end
