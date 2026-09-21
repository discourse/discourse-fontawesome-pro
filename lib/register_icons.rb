# frozen_string_literal: true

module RegisterIcons
  # Icons from core and plugins that the installed Pro package provides, so they can be restyled.
  # Icons without a Pro counterpart, like core's own non-Font Awesome icons, are left out.
  # Plugins can register icons as late as their after_initialize, so call this once boot is done.
  def self.icon_replacements(solid_sprite_path)
    @icon_replacements ||= {}
    @icon_replacements[solid_sprite_path] ||= begin
      if File.file?(solid_sprite_path)
        pro_icons = File.read(solid_sprite_path).scan(/<symbol id="([^"]+)"/).flatten.to_set
        (SvgSprite::SVG_ICONS | DiscoursePluginRegistry.svg_icons)
          .select { |icon| pro_icons.include?(icon) }
          .sort
      else
        []
      end
    end
  end
end
