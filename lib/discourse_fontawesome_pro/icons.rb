# frozen_string_literal: true

module DiscourseFontawesomePro
  module Icons
    STYLE_PREFIXES = {
      "brands" => "fab",
      "solid" => "fas",
      "regular" => "far",
      "light" => "fal",
      "thin" => "fat",
    }.freeze

    FAMILY_PREFIXES = { "sharp" => "fash", "duotone" => "fad", "sharp-duotone" => "fashd" }.freeze

    SPRITE_PREFIXES =
      STYLE_PREFIXES.merge(
        FAMILY_PREFIXES
          .flat_map do |family, family_prefix|
            STYLE_PREFIXES.map do |style, style_prefix|
              ["#{family}-#{style}", "#{family_prefix}-#{style_prefix}"]
            end
          end
          .to_h,
        # The duotone solid sprite has no style in its file name.
        "duotone" => "fad-fas",
      ).freeze

    SYMBOL_ID = /<symbol id="([^"]+)"/
    BATCH_SIZE = 1000
    FETCH_ERROR_KEY = "fetch_error"

    def self.version
      Icon.pick(:version)
    end

    def self.fetch_error
      PluginStore.get(PLUGIN_NAME, FETCH_ERROR_KEY)
    end

    def self.search_icon_ids(keyword, limit:)
      icons = Icon.order(Arel.sql('name COLLATE "C"')).limit(limit)
      icons =
        icons.where("name ILIKE ?", "%#{Icon.sanitize_sql_like(keyword)}%") if keyword.present?
      icons.pluck(:name)
    end

    def self.symbols(icon_ids)
      Icon.where(name: icon_ids).pluck(:name, :symbol).to_h
    end

    # Icons from core and plugins that the stored Pro icons provide, so they can be restyled.
    def self.replaceable
      cache.defer_get_set("replaceable") do
        icons = SvgSprite::SVG_ICONS | DiscoursePluginRegistry.svg_icons

        Icon
          .where(name: icons.map { |icon| "fas-#{icon}" })
          .pluck(:name)
          .map { |name| name.delete_prefix("fas-") }
          .sort
      end
    end

    # Matches the style that `icon-replacements.js` picks in the browser.
    def self.sprite_icons
      family = SiteSetting.fa_icon_family
      style = SiteSetting.fa_icon_style
      return [] if family == "classic" && style == "solid"

      prefix = SPRITE_PREFIXES[family == "classic" ? style : "#{family}-#{style}"]
      replaceable.map { |icon| "#{prefix}-#{icon}" }
    end

    def self.fetch
      token = package_token
      return false if token.nil?

      DistributedMutex.synchronize("#{PLUGIN_NAME}_fetch_icons", validity: 10.minutes) do
        next false if version == Package::VERSION

        begin
          Package.new(token).with_sprites { |sprites| store!(Package::VERSION, sprites) }
        rescue => e
          PluginStore.set(PLUGIN_NAME, FETCH_ERROR_KEY, e.message)
          raise
        end

        PluginStore.remove(PLUGIN_NAME, FETCH_ERROR_KEY)
        true
      end
    end

    def self.check_token
      token = package_token
      return if token.nil?

      if Package.new(token).token_accepted?
        PluginStore.remove(PLUGIN_NAME, FETCH_ERROR_KEY)
      else
        PluginStore.set(PLUGIN_NAME, FETCH_ERROR_KEY, Package::TOKEN_REJECTED)
      end
    end

    def self.package_token
      SiteSetting.fontawesome_auth_token.presence if SiteSetting.fontawesome_pro_icons_enabled
    end

    def self.store!(version, sprites)
      # Seeds run inside a transaction, so this needs a savepoint to roll back on its own.
      Icon.transaction(requires_new: true) do
        Icon.delete_all

        sprites.each do |name, svg|
          prefix = SPRITE_PREFIXES[name]
          next if prefix.nil?

          svg = svg.gsub(SYMBOL_ID, %(<symbol id="#{prefix}-\\1"))

          SvgSprite
            .symbols_for("#{name}-pro", svg, strict: true)
            .each_slice(BATCH_SIZE) do |batch|
              Icon.insert_all!(batch.map { |icon_id, symbol| { name: icon_id, symbol:, version: } })
            end
        end

        raise ArgumentError, "None of the sprites has a known style" if !Icon.exists?
      end

      cache.clear
      SvgSprite.expire_cache
      Site.clear_anon_cache!
    end

    def self.cache
      @cache ||= DistributedCache.new("discourse_fontawesome_pro")
    end
  end
end
