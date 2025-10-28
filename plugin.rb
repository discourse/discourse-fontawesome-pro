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
  style_prefix_mapping = {
    "brands" => "fab",
    "solid" => "fas",
    "regular" => "far",
    "light" => "fal",
    "thin" => "fat",
  }

  family_prefix_mapping = { "sharp" => "fash", "duotone" => "fad", "sharp-duotone" => "fashd" }

  # Load classic icons
  sprite_source =
    "#{Rails.root}/plugins/discourse-fontawesome-pro/fontawesome-workspace/node_modules/@fortawesome/fontawesome-pro/sprites"
  sprite_dest = "#{Rails.root}/vendor/assets/svg-icons/fontawesome-pro"
  FileUtils.mkdir_p(sprite_dest) unless Dir.exist?(sprite_dest)
  style_prefix_mapping.each do |style, style_prefix|
    fsource = "#{sprite_source}/#{style}.svg"
    fname = "#{sprite_dest}/#{style}-pro.svg"
    next unless File.file?(fsource)

    File.open(fsource) do |source_file|
      contents = source_file.read
      contents.gsub!(/<symbol id="(?<id>.*)"/, "<symbol id=\"#{style_prefix}-\\k<id>\"")
      File.open(fname, "w+") { |f| f.write(contents) }
    end
  end

  # Load all other icons

  family_prefix_mapping.each do |family, family_prefix|
    style_prefix_mapping.each do |style, style_prefix|
      fsource = "#{sprite_source}/#{family}-#{style}.svg"
      fname = "#{sprite_dest}/#{family}-#{style}-pro.svg"
      next unless File.file?(fsource)

      File.open(fsource) do |source_file|
        contents = source_file.read
        contents.gsub!(
          /<symbol id="(?<id>.*)"/,
          "<symbol id=\"#{family_prefix}-#{style_prefix}-\\k<id>\"",
        )
        File.open(fname, "w+") { |f| f.write(contents) }
      end
    end
  end

  icon_styles = %w[
    fab
    fas
    far
    fal
    fat
    fash-fab
    fash-fas
    fash-far
    fash-fal
    fash-fat
    fad-fab
    fad-fas
    fad-far
    fad-fal
    fad-fat
    fashd-fab
    fashd-fas
    fashd-far
    fashd-fal
    fashd-fat
  ]

  icon_styles.each do |style|
    RegisterIcons.icon_replacements.each { |icon| register_svg_icon "#{style}-#{icon}" }
  end
end
